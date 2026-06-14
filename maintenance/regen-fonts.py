#!/usr/bin/env python3
"""Regenerate the embedded Japanese font subsets inside ../index.html.

WHY THIS EXISTS
  index.html embeds its fonts as base64 woff2 data: URLs (the @font-face rules in the
  first <style> block). Latin fonts (Cormorant Garamond, JetBrains Mono) carry ASCII and
  rarely change. The Japanese glyphs come from two subsets:

    - Shippori Mincho : 明朝. Used for the literary prose (overview / afterword) and as the
                        serif-stack fallback.
    - M PLUS 1 Code   : ゴシック. Used in the console / terminal stacks
                        ('JetBrains Mono','M PLUS 1 Code',monospace) so Japanese matches the
                        monospaced Latin instead of clashing with a serif.

  Both must contain every non-ASCII character used on the page, or new characters fall back
  to the OS font (fine on a dev Mac, broken on a kiosk without Japanese fonts). When you
  add/edit Japanese text, re-run this.

USAGE
  python3 tools/regen-fonts.py            # regenerate both subsets, rewrite index.html
  python3 tools/regen-fonts.py --check    # report missing glyphs; write nothing

REQUIREMENTS (already present here; reinstall if missing)
  pip3 install --user fonttools brotli      # pyftsubset must be on PATH

SOURCE FONTS
  Downloaded next to this script on first run and cached (git/deploy-ignored). M PLUS 1 Code
  is a variable font; it is instanced to weight 400 before subsetting. If a URL ever rots,
  drop the .ttf in this folder by hand and rerun.
"""
import re, base64, sys, subprocess, shutil, urllib.request, pathlib
from io import BytesIO
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

HERE  = pathlib.Path(__file__).resolve().parent  # <repo>/maintenance  (kept OUTSIDE the
# deployed website/ tree so it is never published — Cloudflare Pages ignores .assetsignore).
HTML  = HERE.parent / "website" / "exhibition" / "index.html"
CHECK = "--check" in sys.argv

# Each entry becomes one embedded @font-face. `instance` (optional) pins a variable-font axis
# before subsetting. Order here is the order new @font-face rules get inserted.
FONTS = [
    {"family": "Shippori Mincho",
     "cache":  "ShipporiMincho-Regular.ttf",
     "url":    "https://github.com/google/fonts/raw/main/ofl/shipporimincho/ShipporiMincho-Regular.ttf",
     "weight": "400", "instance": None},
    {"family": "M PLUS 1 Code",
     "cache":  "MPLUS1Code[wght].ttf",
     "url":    "https://github.com/google/fonts/raw/main/ofl/mplus1code/MPLUS1Code%5Bwght%5D.ttf",
     "weight": "400", "instance": {"wght": 400}},
]

FACE_RE = lambda fam: re.compile(
    r"(@font-face\{font-family:'" + re.escape(fam) + r"';[^}]*?base64,)([A-Za-z0-9+/=]+)(\))")


def cmap_codes(tt):
    s = set()
    for t in tt["cmap"].tables:
        s |= set(t.cmap.keys())
    return s


def ensure_source(font):
    cache = HERE / font["cache"]
    if not cache.exists():
        print(f"  downloading {font['family']} -> {cache.name}")
        try:
            with urllib.request.urlopen(font["url"]) as r, open(cache, "wb") as f:
                shutil.copyfileobj(r, f)
        except Exception as e:
            sys.exit(f"!! download failed for {font['family']}: {e}\n"
                     f"   Place the .ttf at {cache} by hand and rerun.")
    return cache


def make_subset(font, target):
    """Return (woff2_bytes, source_cmap_codes)."""
    src = ensure_source(font)
    src_path = src
    # Variable font -> pin to a single weight so the subset is a plain static instance.
    if font["instance"]:
        tt = TTFont(src)
        if "fvar" in tt:
            instantiateVariableFont(tt, font["instance"], inplace=True)
        static = HERE / ("_static_" + font["cache"].replace("[wght]", "") )
        tt.save(static)
        src_path = static
    src_cmap = cmap_codes(TTFont(src_path))
    chars_file = HERE / "_chars.txt"
    chars_file.write_text("".join(target), encoding="utf-8")
    out = HERE / "_subset.woff2"
    subprocess.run(["pyftsubset", str(src_path), f"--text-file={chars_file}",
                    "--flavor=woff2", "--layout-features=*", f"--output-file={out}"], check=True)
    data = out.read_bytes()
    chars_file.unlink(missing_ok=True)
    out.unlink(missing_ok=True)
    if font["instance"]:
        pathlib.Path(src_path).unlink(missing_ok=True)
    return data, src_cmap


def face_block(font, b64):
    return ("@font-face{font-family:'" + font["family"] + "';font-style:normal;font-weight:"
            + font["weight"] + ";font-display:swap;src:url(data:font/woff2;base64,"
            + b64 + ") format('woff2')}")


def main():
    html = HTML.read_text(encoding="utf-8")
    # Target = every non-ASCII codepoint on the page (base64 + JS are pure ASCII, so all
    # non-ASCII characters are genuine on-screen text).
    target = sorted({c for c in html if ord(c) > 0x7F}, key=ord)
    print(f"non-ASCII characters used in page: {len(target)}")

    if CHECK:
        for font in FONTS:
            m = FACE_RE(font["family"]).search(html)
            if not m:
                print(f"[{font['family']}] not embedded yet (will be added on a real run)")
                continue
            have = cmap_codes(TTFont(BytesIO(base64.b64decode(m.group(2)))))
            missing = [c for c in target if ord(c) not in have]
            print(f"[{font['family']}] missing {len(missing)}: {''.join(missing)}")
        return

    for font in FONTS:
        print(f"[{font['family']}]")
        data, src_cmap = make_subset(font, target)
        lacks = [c for c in target if ord(c) not in src_cmap]
        if lacks:
            print(f"  source lacks {len(lacks)} chars (will OS-fallback): {''.join(lacks)}")
        b64 = base64.b64encode(data).decode("ascii")
        print(f"  subset {len(data)/1024:.1f}KB")
        face = FACE_RE(font["family"])
        if face.search(html):
            html = face.sub(lambda m: m.group(1) + b64 + m.group(3), html, count=1)
        else:
            # Insert a new @font-face right after the last existing one.
            last = None
            for mm in re.finditer(r"@font-face\{[^}]*?base64,[A-Za-z0-9+/=]+\)[^}]*?\}", html):
                last = mm
            if not last:
                sys.exit("!! no existing @font-face to anchor insertion")
            ins = last.end()
            html = html[:ins] + "\n" + face_block(font, b64) + html[ins:]
            print(f"  added new @font-face for {font['family']}")

    HTML.write_text(html, encoding="utf-8")
    print(f"rewrote {HTML}")


if __name__ == "__main__":
    main()
