import { json, deviceClass } from "./_shared.js";

// POST /api/feedback  { text, session?, lang? }  ->  { ok }
// Anonymous free-text note. No IP, no cookies; country/device are coarse.
export async function onRequestPost({ request, env }) {
  let b;
  try { b = await request.json(); } catch { b = {}; }
  let text = typeof b?.text === "string" ? b.text.trim() : "";
  if (text.length < 1) return json({ ok: false, error: "empty" }, 400);
  if (text.length > 2000) text = text.slice(0, 2000);

  if (env.DB) {
    try {
      const country = request.cf?.country || null;
      const device = deviceClass(request.headers.get("user-agent"));
      const lang = b.lang === "ja" || b.lang === "en" ? b.lang : null;
      const session = typeof b.session === "string" ? b.session.slice(0, 24) : null;
      await env.DB.prepare(
        "INSERT INTO feedback (ts,text,lang,country,device,session) VALUES (?,?,?,?,?,?)"
      ).bind(Date.now(), text, lang, country, device, session).run();
    } catch (e) { /* never break the response */ }
  }
  return json({ ok: true });
}
