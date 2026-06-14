import { createPublicClient, createWalletClient, http, parseEventLogs } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { mainnet } from "viem/chains";

// Cat contract addresses on Ethereum mainnet. Keep in sync with CATS in exhibition/index.html.
export const CAT_ADDRS = [
  "0xa9e8735dc5f9020f299e1de27d5ac14d43e44dd2", // 0 ReentrancyCat
  "0x9050628cae4268e4701d4b011c99db30bc402b1c", // 1 PredictableCat
  "0xf3fe43009429dd8450d916f7118970a52f130cbe", // 2 OverflowCat
  "0x81b4b28c51fde85c062b6ce88fe60cb85bc16fc1", // 3 UnprotectedCat
  "0xa109dc01fba2557ea87d645f4a9b3b0ceedf625f", // 4 MisspelledCat
];

export const REMEMBER_ABI = [
  { type: "function", name: "remember", stateMutability: "view", inputs: [], outputs: [{ type: "bool" }] },
];

export const MEOW_ABI = [
  { type: "event", name: "Meow", inputs: [
    { name: "who", type: "address", indexed: true },
    { name: "vulnerability", type: "string", indexed: false },
  ] },
];

export const CARESS_ABI = [
  ...MEOW_ABI,
  // caress() — same selector for Seeker (payable) and the cats; value defaults to 0
  { type: "function", name: "caress", stateMutability: "payable", inputs: [] },
  // Prophet.caress(cat)
  { type: "function", name: "caress", stateMutability: "nonpayable", inputs: [{ name: "cat", type: "address" }] },
  { type: "function", name: "batchTransfer", stateMutability: "nonpayable", inputs: [
    { name: "_receivers", type: "address[]" }, { name: "_value", type: "uint256" } ] },
  { type: "function", name: "init", stateMutability: "nonpayable", inputs: [{ name: "o", type: "address" }] },
  { type: "function", name: "MisspeledCat", stateMutability: "nonpayable", inputs: [{ name: "o", type: "address" }] },
];

export const truthy = (v) => v === "1" || v === "true" || v === true;

// Exhibition window (JST, UTC+9). Real caress() transactions fire ONLY inside it; outside is
// always dry-run, so forgetting to flip DRY_RUN back after the show cannot send live tx.
// 2026-07-15 00:00 JST .. end of 2026-07-20 (i.e. < 2026-07-21 00:00 JST). Month is 0-indexed.
const EXHIBITION_START = Date.UTC(2026, 6, 14, 15, 0, 0); // 2026-07-15 00:00 JST
const EXHIBITION_END   = Date.UTC(2026, 6, 20, 15, 0, 0); // 2026-07-21 00:00 JST

export function withinExhibition(now = Date.now()) {
  return now >= EXHIBITION_START && now < EXHIBITION_END;
}

// caress is dry-run when explicitly flagged (manual override), when no signing key is
// configured (fail-safe), or outside the exhibition window. To go live during the show,
// set DRY_RUN="false" and configure the secrets; the window still bounds real sending.
export function caressDryRun(env) {
  return truthy(env.DRY_RUN) || !env.PRIVATE_KEY || !withinExhibition();
}

export function rpcUrl(env) {
  const u = env.RPC_URL;
  if (!u) throw new Error("RPC_URL not configured");
  return u;
}

export function publicClient(env) {
  return createPublicClient({ chain: mainnet, transport: http(rpcUrl(env)) });
}

export function walletClient(env) {
  const pk = env.PRIVATE_KEY;
  if (!pk) throw new Error("PRIVATE_KEY not configured");
  const account = privateKeyToAccount(pk.startsWith("0x") ? pk : "0x" + pk);
  return {
    account,
    wallet: createWalletClient({ account, chain: mainnet, transport: http(rpcUrl(env)) }),
    pub: publicClient(env),
  };
}

export function hasMeow(receipt) {
  const logs = parseEventLogs({ abi: MEOW_ABI, eventName: "Meow", logs: receipt.logs });
  return logs.length > 0;
}

export function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });
}

export function parseCat(body) {
  const i = Number(body?.cat);
  if (!Number.isInteger(i) || i < 0 || i > 4) return null;
  return i;
}

export function deviceClass(ua) {
  ua = ua || "";
  if (/iPad|Tablet/i.test(ua)) return "tablet";
  if (/Mobi|Android|iPhone/i.test(ua)) return "mobile";
  return "desktop";
}

// Anonymous interaction log: country (coarse) + device class only. No IP, no cookies, no UA stored.
export async function logEvent(env, request, d) {
  if (!env.DB) return;
  try {
    const country = request.cf?.country || null;
    const device = deviceClass(request.headers.get("user-agent"));
    const lang = d.lang === "en" || d.lang === "ja" ? d.lang : null;
    const session = typeof d.session === "string" ? d.session.slice(0, 24) : null;
    let ref = null;
    if (d.ref) { try { ref = new URL(d.ref).hostname || null; } catch { ref = null; } }
    await env.DB.prepare(
      "INSERT INTO events (ts,session,type,cat,country,device,lang,path,ref) VALUES (?,?,?,?,?,?,?,?,?)"
    ).bind(Date.now(), session, d.type, d.cat == null ? null : d.cat, country, device, lang, d.path || null, ref).run();
  } catch (e) { /* logging must never break the response */ }
}
