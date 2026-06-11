import { logEvent } from "./_shared.js";

const TYPES = new Set(["page_view", "tab", "remember", "caress", "help", "lang"]);

// POST /api/event  { type, cat?, session?, lang?, path? }  -> 204
export async function onRequestPost({ request, env }) {
  let b;
  try { b = await request.json(); } catch { b = {}; }
  if (!TYPES.has(b?.type)) return new Response(null, { status: 400 });

  let cat = null;
  if (b.cat != null) {
    const i = Number(b.cat);
    if (Number.isInteger(i) && i >= 0 && i <= 4) cat = i;
  }
  await logEvent(env, request, {
    type: b.type,
    cat,
    session: b.session,
    lang: b.lang,
    path: typeof b.path === "string" ? b.path.slice(0, 128) : null,
    ref: typeof b.ref === "string" ? b.ref.slice(0, 300) : null,
  });
  return new Response(null, { status: 204 });
}
