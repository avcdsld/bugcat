import { catAddrs, REMEMBER_ABI, publicClient, json, parseCat, truthy, logEvent, chainName } from "./_shared.js";

// Edge cache TTL for the on-chain remember() read. The state never changes (the historical
// contracts are immutable), so this only exists to absorb traffic bursts during the exhibition —
// many concurrent visitors on the same colo share one RPC read per window.
const REMEMBER_CACHE_TTL = 20;

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

  // caches.default is keyed by Request URL and scoped to the worker's origin. POST bodies aren't
  // cacheable, so synthesize a same-origin GET URL that uniquely identifies (chain, cat address).
  const addr = catAddrs(env)[cat];
  const origin = new URL(request.url).origin;
  const cacheKey = new Request(
    `${origin}/__cache/remember/${chainName(env)}/${addr.toLowerCase()}`,
    { method: "GET" }
  );
  const cache = caches.default;
  const hit = await cache.match(cacheKey);
  if (hit) return hit;

  try {
    const pub = publicClient(env);
    const [exists, block] = await Promise.all([
      pub.readContract({ address: addr, abi: REMEMBER_ABI, functionName: "remember" }),
      pub.getBlockNumber(),
    ]);
    const res = new Response(
      JSON.stringify({ ok: true, exists: Boolean(exists), block: Number(block) }),
      {
        headers: {
          "content-type": "application/json",
          "cache-control": `public, max-age=${REMEMBER_CACHE_TTL}`,
        },
      }
    );
    // clone() because cache.put consumes the body — return the original response.
    await cache.put(cacheKey, res.clone());
    return res;
  } catch (e) {
    return json({ ok: false, error: String(e?.message || e) }, 502);
  }
}
