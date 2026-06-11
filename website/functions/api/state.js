import { json } from "./_shared.js";

// POST /api/state -> { ok, caress }  total caresses across all visitors (drives the shared field).
// POST (not GET) because the SPA not-found handling shadows GET requests before Functions run.
export async function onRequestPost({ env }) {
  if (!env.DB) return json({ ok: true, caress: 0 });
  try {
    const r = await env.DB.prepare("SELECT COUNT(*) AS n FROM events WHERE type='caress'").first();
    return json({ ok: true, caress: Number(r?.n || 0) });
  } catch (e) {
    return json({ ok: true, caress: 0 });
  }
}
