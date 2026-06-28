const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Deploys ONLY the helper contracts needed to make the live caress flow work on Ethereum mainnet,
// against the already-deployed mainnet cats (see CAT_ADDRS in website/functions/api/_shared.js).
// The cats themselves are NOT redeployed.
//
//   Seeker    -> bound at construction to the existing mainnet ReentrancyCat (cat 0)
//   Prophet   -> cat-agnostic caress(cat); one deploy serves PredictableCat (cat 1)
//   Caretaker -> cat-agnostic; one deploy serves OverflowCat (2), UnprotectedCat (3),
//                MisspelledCat (4). Does setup+caress in one atomic tx so a Meow can't be lost
//                to a concurrent caress (the OverflowCat re-overflow race).
//
// Run locally (RPC egress + funded key required):
//   cd v8 && npx hardhat run scripts/deploy-mainnet-helpers.js --network mainnet

// Existing mainnet ReentrancyCat (cat 0). Must match CAT_ADDRS[0] in _shared.js. Override via env
// REENTRANCY_CAT_ADDR / PREDICTABLE_CAT_ADDR if a cat is ever redeployed. Both must match
// CAT_ADDRS[0] and CAT_ADDRS[1] in website/functions/api/_shared.js.
const MAINNET_REENTRANCY_CAT = "0xa9e8735dc5f9020f299e1de27d5ac14d43e44dd2";  // cat 0
const MAINNET_PREDICTABLE_CAT = "0x9050628cae4268e4701d4b011c99db30bc402b1c"; // cat 1
const MAINNET_OVERFLOW_CAT = "0xf3fe43009429dd8450d916f7118970a52f130cbe";    // cat 2
const MAINNET_UNPROTECTED_CAT = "0x81b4b28c51fde85c062b6ce88fe60cb85bc16fc1"; // cat 3
const MAINNET_MISSPELLED_CAT = "0xa109dc01fba2557ea87d645f4a9b3b0ceedf625f";  // cat 4

// Wait for deployed bytecode to appear at an address (eth_getCode returns a plain string, so it
// never hits the response-parsing bug below).
async function waitForCode(provider, addr, timeoutMs = 150000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const code = await provider.getCode(addr);
    if (code && code !== "0x") return true;
    await new Promise((r) => setTimeout(r, 4000));
  }
  return false;
}

// Deploy that tolerates non-standard RPCs. Some providers (e.g. Alchemy) return to:"" for a
// *pending* contract-creation tx, which ethers v6 rejects while formatting the response — even
// though the tx was broadcast fine. On that failure, recover by computing the deterministic CREATE
// address (sender + nonce) and confirming code lands there. Compliant RPCs take the normal path.
async function deployRobust(name, args = []) {
  const [signer] = await ethers.getSigners();
  const factory = await ethers.getContractFactory(name);
  const nonce = await signer.getNonce("pending");
  try {
    const c = await factory.deploy(...args);
    await c.waitForDeployment();
    return c.target;
  } catch (e) {
    const addr = ethers.getCreateAddress({ from: signer.address, nonce });
    console.log(`   (RPC could not parse the pending tx; waiting for code at ${addr} ...)`);
    if (await waitForCode(signer.provider, addr)) return addr;
    throw e;
  }
}

async function main() {
  const reentrancyCat = (process.env.REENTRANCY_CAT_ADDR || MAINNET_REENTRANCY_CAT).trim();
  if (!ethers.isAddress(reentrancyCat)) {
    throw new Error(`Invalid ReentrancyCat address: ${reentrancyCat}`);
  }
  const predictableCat = (process.env.PREDICTABLE_CAT_ADDR || MAINNET_PREDICTABLE_CAT).trim();
  if (!ethers.isAddress(predictableCat)) {
    throw new Error(`Invalid PredictableCat address: ${predictableCat}`);
  }

  const [deployer] = await ethers.getSigners();
  console.log(`Deploying v8 helpers to ${network.name}...`);
  console.log("Deployer       :", deployer.address);
  console.log("Balance        :", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");
  console.log("ReentrancyCat  :", reentrancyCat, "(existing, unchanged)");
  console.log("PredictableCat :", predictableCat, "(existing, unchanged)\n");

  // Resumable: pass SEEKER_ADDR / PROPHET_ADDR to reuse an already-deployed helper and skip that
  // step. Useful when a flaky RPC crashes the script after a deploy tx was already broadcast.
  let seekerAddr = (process.env.SEEKER_ADDR || "").trim();
  if (seekerAddr) {
    if (!ethers.isAddress(seekerAddr)) throw new Error(`Invalid SEEKER_ADDR: ${seekerAddr}`);
    console.log("1. Seeker (reusing SEEKER_ADDR, skip deploy)...");
    console.log("   ->", seekerAddr);
  } else {
    console.log("1. Seeker (for ReentrancyCat)...");
    seekerAddr = await deployRobust("Seeker", [reentrancyCat]);
    console.log("   ->", seekerAddr);
  }

  let prophetAddr = (process.env.PROPHET_ADDR || "").trim();
  if (prophetAddr) {
    if (!ethers.isAddress(prophetAddr)) throw new Error(`Invalid PROPHET_ADDR: ${prophetAddr}`);
    console.log("2. Prophet (reusing PROPHET_ADDR, skip deploy)...");
    console.log("   ->", prophetAddr);
  } else {
    console.log("2. Prophet (for PredictableCat)...");
    prophetAddr = await deployRobust("Prophet", []);
    console.log("   ->", prophetAddr);
  }

  let caretakerAddr = (process.env.CARETAKER_ADDR || "").trim();
  if (caretakerAddr) {
    if (!ethers.isAddress(caretakerAddr)) throw new Error(`Invalid CARETAKER_ADDR: ${caretakerAddr}`);
    console.log("3. Caretaker (reusing CARETAKER_ADDR, skip deploy)...");
    console.log("   ->", caretakerAddr);
  } else {
    console.log("3. Caretaker (for OverflowCat / UnprotectedCat / MisspelledCat)...");
    caretakerAddr = await deployRobust("Caretaker", []);
    console.log("   ->", caretakerAddr);
  }

  const out = {
    network: network.name,
    deployer: deployer.address,
    ReentrancyCat: reentrancyCat,   // existing cat 0 (not deployed here)
    PredictableCat: predictableCat, // existing cat 1 (not deployed here; needed by feed.js)
    OverflowCat: MAINNET_OVERFLOW_CAT,       // existing cat 2 (served by Caretaker)
    UnprotectedCat: MAINNET_UNPROTECTED_CAT, // existing cat 3 (served by Caretaker)
    MisspelledCat: MAINNET_MISSPELLED_CAT,   // existing cat 4 (served by Caretaker)
    Seeker: seekerAddr,
    Prophet: prophetAddr,
    Caretaker: caretakerAddr,
  };
  const file = path.join(__dirname, "..", `deployment-${network.name}.json`);
  fs.writeFileSync(file, JSON.stringify(out, null, 2) + "\n");

  console.log("\n=== v8 mainnet helpers deployed ===");
  console.log(JSON.stringify(out, null, 2));
  console.log(`\nSaved to ${file}`);

  console.log("\n--- wrangler (Cloudflare Pages) ---");
  console.log(`SEEKER_ADDR    = ${seekerAddr}`);
  console.log(`PROPHET_ADDR   = ${prophetAddr}`);
  console.log(`CARETAKER_ADDR = ${caretakerAddr}`);

  console.log("\n--- verify (after a few confirmations) ---");
  console.log(`npx hardhat verify --network ${network.name} ${seekerAddr} ${reentrancyCat}`);
  console.log(`npx hardhat verify --network ${network.name} ${prophetAddr}`);
  console.log(`npx hardhat verify --network ${network.name} ${caretakerAddr}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
