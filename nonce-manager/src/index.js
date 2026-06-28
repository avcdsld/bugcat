import { DurableObject } from "cloudflare:workers";
import { createPublicClient, createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { mainnet, sepolia } from "viem/chains";

// DO-only Worker. Pages binds this DO via [[durable_objects.bindings]] with script_name and calls
// submit() through the RPC binding — there are no HTTP routes here on purpose.
//
// Why a separate Worker: Pages Functions cannot define Durable Object classes, only bind to ones
// hosted on a Worker. So all the wallet/nonce logic lives here; Pages just encodes the call data
// and forwards it to submit().
export class NonceManager extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.nextNonce = null;
    this.queue = Promise.resolve();
    this.clients = null;
  }

  _clients() {
    if (this.clients) return this.clients;
    const pk = this.env.PRIVATE_KEY;
    if (!pk) throw new Error("PRIVATE_KEY not configured");
    if (!this.env.RPC_URL) throw new Error("RPC_URL not configured");
    const account = privateKeyToAccount(pk.startsWith("0x") ? pk : "0x" + pk);
    const chain = this.env.CHAIN === "sepolia" ? sepolia : mainnet;
    const transport = http(this.env.RPC_URL);
    this.clients = {
      account,
      wallet: createWalletClient({ account, chain, transport }),
      pub: createPublicClient({ chain, transport }),
    };
    return this.clients;
  }

  // Submit a single transaction with a serialized, server-tracked nonce.
  // value / gas accepted as bigint or numeric string. Returns { hash } or { error }.
  async submit({ to, data, value, gas }) {
    const run = async () => {
      const { account, wallet, pub } = this._clients();
      if (this.nextNonce == null) {
        this.nextNonce = await pub.getTransactionCount({
          address: account.address,
          blockTag: "pending",
        });
      }
      const nonce = this.nextNonce;
      try {
        const hash = await wallet.sendTransaction({
          to,
          data,
          value: value != null ? BigInt(value) : 0n,
          nonce,
          ...(gas ? { gas: BigInt(gas) } : {}),
        });
        this.nextNonce = nonce + 1;
        return { hash };
      } catch (e) {
        // Drop cached nonce so the next submit refetches from chain.
        this.nextNonce = null;
        return { error: String(e?.message || e) };
      }
    };
    const next = this.queue.then(run, run);
    this.queue = next.then(() => {}, () => {});
    return next;
  }

  // Exposed for callers that need the sender address (e.g. caress() args for cat 2/3/4) without
  // having to derive it from PRIVATE_KEY themselves.
  async senderAddress() {
    return this._clients().account.address;
  }
}

export default {
  async fetch() {
    return new Response("nonce-manager: DO-only worker, no HTTP routes", { status: 404 });
  },
};
