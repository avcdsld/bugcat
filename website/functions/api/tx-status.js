import { json, publicClient, hasMeow, chainName } from "./_shared.js";

// GET /api/tx-status?hash=0x...  ->  { ok, confirmed, meow, block, chain }
// Lightweight receipt poll. While the tx is in the mempool returns confirmed: false; once mined
// returns confirmed: true plus meow (from the parsed Meow event) and the block number. The
// browser polls this with backoff so the caress() submit can return without blocking on the
// 15–25s receipt wait.
export async function onRequestGet({ request, env }) {
  const url = new URL(request.url);
  const hash = url.searchParams.get("hash");
  if (!hash || !/^0x[0-9a-fA-F]{64}$/.test(hash)) {
    return json({ ok: false, error: "invalid hash" }, 400);
  }
  try {
    const pub = publicClient(env);
    let receipt;
    try {
      receipt = await pub.getTransactionReceipt({ hash });
    } catch (e) {
      // viem throws TransactionReceiptNotFoundError until the tx mines — treat as pending.
      if (/not be found|TransactionReceiptNotFound/i.test(String(e))) {
        return json({ ok: true, confirmed: false, chain: chainName(env) });
      }
      throw e;
    }
    if (!receipt) {
      return json({ ok: true, confirmed: false, chain: chainName(env) });
    }
    return json({
      ok: true,
      confirmed: true,
      meow: hasMeow(receipt),
      block: Number(receipt.blockNumber),
      chain: chainName(env),
    });
  } catch (e) {
    return json({ ok: false, error: String(e?.message || e) }, 502);
  }
}
