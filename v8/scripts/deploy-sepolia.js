const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Deploys the v8 (Solidity 0.8.x) BugCats and their helpers to whichever network is passed via
// --network (intended for sepolia; also works for mainnet). Cats 0/1 in the website's index order:
//   0 ReentrancyCat  (caressed via Seeker)
//   1 PredictableCat (caressed via Prophet)
// The v4 cats (2 OverflowCat, 3 UnprotectedCat, 4 MisspelledCat) are deployed by v4/scripts/deploy-sepolia.js.
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying v8 contracts to ${network.name}...`);
  console.log("Deployer:", deployer.address);
  console.log("Balance :", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH\n");

  console.log("1. ReentrancyCat...");
  const reentrancyCat = await (await ethers.getContractFactory("ReentrancyCat")).deploy();
  await reentrancyCat.waitForDeployment();
  console.log("   ->", reentrancyCat.target);

  console.log("2. Seeker (for ReentrancyCat)...");
  const seeker = await (await ethers.getContractFactory("Seeker")).deploy(reentrancyCat.target);
  await seeker.waitForDeployment();
  console.log("   ->", seeker.target);

  console.log("3. PredictableCat...");
  const predictableCat = await (await ethers.getContractFactory("PredictableCat")).deploy();
  await predictableCat.waitForDeployment();
  console.log("   ->", predictableCat.target);

  console.log("4. Prophet (for PredictableCat)...");
  const prophet = await (await ethers.getContractFactory("Prophet")).deploy();
  await prophet.waitForDeployment();
  console.log("   ->", prophet.target);

  const out = {
    network: network.name,
    deployer: deployer.address,
    ReentrancyCat: reentrancyCat.target,   // cat 0
    Seeker: seeker.target,
    PredictableCat: predictableCat.target,  // cat 1
    Prophet: prophet.target,
  };
  const file = path.join(__dirname, `..`, `deployment-${network.name}.json`);
  fs.writeFileSync(file, JSON.stringify(out, null, 2) + "\n");

  console.log("\n=== v8 deployment complete ===");
  console.log(JSON.stringify(out, null, 2));
  console.log(`\nSaved to ${file}`);

  console.log("\n--- wrangler (Cloudflare Pages) ---");
  console.log(`SEEKER_ADDR  = ${seeker.target}`);
  console.log(`PROPHET_ADDR = ${prophet.target}`);
  console.log("\n--- website/functions/api/_shared.js CAT_ADDRS_SEPOLIA ---");
  console.log(`[0] ReentrancyCat  = ${reentrancyCat.target}`);
  console.log(`[1] PredictableCat = ${predictableCat.target}`);

  console.log("\n--- verify (after a few confirmations) ---");
  console.log(`npx hardhat verify --network ${network.name} ${reentrancyCat.target}`);
  console.log(`npx hardhat verify --network ${network.name} ${seeker.target} ${reentrancyCat.target}`);
  console.log(`npx hardhat verify --network ${network.name} ${predictableCat.target}`);
  console.log(`npx hardhat verify --network ${network.name} ${prophet.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
