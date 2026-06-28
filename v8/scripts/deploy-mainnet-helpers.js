const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Deploys ONLY the two helper contracts needed to make the live caress flow work on Ethereum
// mainnet, against the already-deployed mainnet cats (see CAT_ADDRS in
// website/functions/api/_shared.js). The cats themselves are NOT redeployed.
//
//   Seeker  -> bound at construction to the existing mainnet ReentrancyCat (cat 0)
//   Prophet -> cat-agnostic (caress(address cat)); a single deploy serves PredictableCat (cat 1)
//
// Cats 2/3/4 (OverflowCat / UnprotectedCat / MisspelledCat) are exploited directly by the website
// and need no helper, so nothing from v4 is deployed here.
//
// Run locally (RPC egress + funded key required):
//   cd v8 && npx hardhat run scripts/deploy-mainnet-helpers.js --network mainnet

// Existing mainnet ReentrancyCat (cat 0). Must match CAT_ADDRS[0] in _shared.js. Override via env
// REENTRANCY_CAT_ADDR if the cat is ever redeployed.
const MAINNET_REENTRANCY_CAT = "0xa9e8735dc5f9020f299e1de27d5ac14d43e44dd2";

async function main() {
  const reentrancyCat = (process.env.REENTRANCY_CAT_ADDR || MAINNET_REENTRANCY_CAT).trim();
  if (!ethers.isAddress(reentrancyCat)) {
    throw new Error(`Invalid ReentrancyCat address: ${reentrancyCat}`);
  }

  const [deployer] = await ethers.getSigners();
  console.log(`Deploying v8 helpers to ${network.name}...`);
  console.log("Deployer       :", deployer.address);
  console.log("Balance        :", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");
  console.log("ReentrancyCat  :", reentrancyCat, "(existing, unchanged)\n");

  console.log("1. Seeker (for ReentrancyCat)...");
  const seeker = await (await ethers.getContractFactory("Seeker")).deploy(reentrancyCat);
  await seeker.waitForDeployment();
  console.log("   ->", seeker.target);

  console.log("2. Prophet (for PredictableCat)...");
  const prophet = await (await ethers.getContractFactory("Prophet")).deploy();
  await prophet.waitForDeployment();
  console.log("   ->", prophet.target);

  const out = {
    network: network.name,
    deployer: deployer.address,
    ReentrancyCat: reentrancyCat, // existing cat 0 (not deployed here)
    Seeker: seeker.target,
    Prophet: prophet.target,
  };
  const file = path.join(__dirname, "..", `deployment-${network.name}.json`);
  fs.writeFileSync(file, JSON.stringify(out, null, 2) + "\n");

  console.log("\n=== v8 mainnet helpers deployed ===");
  console.log(JSON.stringify(out, null, 2));
  console.log(`\nSaved to ${file}`);

  console.log("\n--- wrangler (Cloudflare Pages) ---");
  console.log(`SEEKER_ADDR  = ${seeker.target}`);
  console.log(`PROPHET_ADDR = ${prophet.target}`);

  console.log("\n--- verify (after a few confirmations) ---");
  console.log(`npx hardhat verify --network ${network.name} ${seeker.target} ${reentrancyCat}`);
  console.log(`npx hardhat verify --network ${network.name} ${prophet.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
