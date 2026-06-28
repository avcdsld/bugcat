import { encodeFunctionData } from "viem";
import { catAddrs, CARESS_ABI, json, parseCat, caressDryRun, logEvent, chainName } from "./_shared.js";

// POST /api/caress  { cat: 0..4 }  ->  { ok, txHash, hashes, pending, chain }
// Broadcasts the exploit txs through the NonceManager DO and returns as soon as the final tx is
// in the mempool (no receipt wait). The browser then polls /api/tx-status?hash=... so the
// Etherscan link can appear immediately and the confirmed state arrives without blocking submit.
export async function onRequestPost({ request, env }) {
  let body;
  try { body = await request.json(); } catch { body = {}; }
  const cat = parseCat(body);
  if (cat === null) return json({ ok: false, error: "invalid cat" }, 400);
  await logEvent(env, request, { type: "caress", cat, session: body.session, lang: body.lang });

  if (caressDryRun(env)) {
    return json({ ok: true, txHash: null, block: null, meow: true, dryRun: true, chain: chainName(env) });
  }

  try {
    const catAddr = catAddrs(env)[cat];
    const stub = env.NONCE_MANAGER.getByName("default");

    // Encode args here (caress.js owns the ABI) and pass raw bytes to the DO. The DO does
    // sendTransaction with a managed nonce; no ABI roundtrip needed.
    const submit = async (to, functionName, args = [], value = 0n, gas) => {
      const data = encodeFunctionData({ abi: CARESS_ABI, functionName, args });
      const res = await stub.submit({
        to,
        data,
        value: value.toString(),
        ...(gas ? { gas: gas.toString() } : {}),
      });
      if (res.error) throw new Error(res.error);
      return res.hash;
    };

    const hashes = [];
    if (cat === 0) {
      // ReentrancyCat via Seeker: deposit -> withdraw -> reenter -> caress, all in one tx.
      const seeker = env.SEEKER_ADDR;
      if (!seeker) throw new Error("SEEKER_ADDR not configured");
      const value = env.SEEKER_VALUE ? BigInt(env.SEEKER_VALUE) : 1n;
      hashes.push(await submit(seeker, "caress", [], value));
    } else if (cat === 1) {
      // PredictableCat via Prophet: a single block-prediction attempt; all-or-nothing (~1/2).
      // Explicit gas because the winning branch is heavier than estimateGas's cheap-branch view.
      const prophet = env.PROPHET_ADDR;
      if (!prophet) throw new Error("PROPHET_ADDR not configured");
      hashes.push(await submit(prophet, "caress", [catAddr], 0n, 500000n));
    } else {
      // Cats 2/3/4 via Caretaker: the setup (overflow / init / misspelled-constructor) and the
      // caress happen in ONE atomic tx, so the state a Meow depends on can't be undone by a
      // concurrent caress. In particular this kills the OverflowCat re-overflow race where two
      // near-simultaneous setups summed balance back to 0 and neither cat meowed.
      const caretaker = env.CARETAKER_ADDR;
      if (!caretaker) throw new Error("CARETAKER_ADDR not configured");
      const fn = cat === 2 ? "overflow" : cat === 3 ? "claim" : "rename";
      // Explicit gas: estimateGas may see the cheap already-primed branch and under-fund a run
      // that takes the setup branch (same hazard as cat 1).
      hashes.push(await submit(caretaker, fn, [catAddr], 0n, 300000n));
    }

    return json({
      ok: true,
      txHash: hashes[hashes.length - 1],
      hashes,
      pending: true,
      chain: chainName(env),
    });
  } catch (e) {
    const msg = String(e?.message || e);
    // Sender ran out of gas money. Don't surface a raw failure — pause real sends and degrade to a
    // dry-run meow with an honest "paused" note so the piece keeps working until the key is topped up.
    if (/insufficient funds/i.test(msg)) {
      return json({ ok: true, txHash: null, meow: true, dryRun: true, paused: true, chain: chainName(env) });
    }
    return json({ ok: false, error: msg }, 502);
  }
}
