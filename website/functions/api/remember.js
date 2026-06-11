import { CAT_ADDRS, REMEMBER_ABI, publicClient, json, parseCat, truthy, logEvent } from "./_shared.js";

// POST /api/remember  { cat: 0..4 }  ->  { ok, exists }
export async function onRequestPost({ request, env }) {
  let body;
  try { body = await request.json(); } catch { body = {}; }
  const cat = parseCat(body);
  if (cat === null) return json({ ok: false, error: "invalid cat" }, 400);
  await logEvent(env, request, { type: "remember", cat, session: body.session, lang: body.lang });

  // Dry-run (or no RPC configured): report the historical contract as present without a chain read.
  if (truthy(env.DRY_RUN) || !env.RPC_URL) {
    return json({ ok: true, exists: true, dryRun: true });
  }

  try {
    const pub = publicClient(env);
    const [exists, block] = await Promise.all([
      pub.readContract({ address: CAT_ADDRS[cat], abi: REMEMBER_ABI, functionName: "remember" }),
      pub.getBlockNumber(),
    ]);
    return json({ ok: true, exists: Boolean(exists), block: Number(block) });
  } catch (e) {
    return json({ ok: false, error: String(e?.message || e) }, 502);
  }
}
