const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Deploys the v4 (Solidity 0.4.26) BugCats to whichever network is passed via --network
// (intended for sepolia; also works for mainnet). Website index order:
//   2 OverflowCat
//   3 UnprotectedCat
//   4 MisspelledCat
// Cats 0 ReentrancyCat / 1 PredictableCat are deployed by v8/scripts/deploy-sepolia.js.
// These cats are caressed directly by the API (no helper contract needed), so nothing else to wire.
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying v4 contracts to ${network.name}...`);
  console.log("Deployer:", deployer.address);
  console.log("Balance :", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH\n");

  console.log("1. OverflowCat...");
  const overflowCat = await (await ethers.getContractFactory("OverflowCat")).deploy();
  await overflowCat.waitForDeployment();
  console.log("   ->", overflowCat.target);

  console.log("2. UnprotectedCat...");
  const unprotectedCat = await (await ethers.getContractFactory("UnprotectedCat")).deploy();
  await unprotectedCat.waitForDeployment();
  console.log("   ->", unprotectedCat.target);

  console.log("3. MisspelledCat...");
  const misspelledCat = await (await ethers.getContractFactory("MisspelledCat")).deploy();
  await misspelledCat.waitForDeployment();
  console.log("   ->", misspelledCat.target);

  const out = {
    network: network.name,
    deployer: deployer.address,
    OverflowCat: overflowCat.target,      // cat 2
    UnprotectedCat: unprotectedCat.target, // cat 3
    MisspelledCat: misspelledCat.target,   // cat 4
  };
  const file = path.join(__dirname, `..`, `deployment-${network.name}.json`);
  fs.writeFileSync(file, JSON.stringify(out, null, 2) + "\n");

  console.log("\n=== v4 deployment complete ===");
  console.log(JSON.stringify(out, null, 2));
  console.log(`\nSaved to ${file}`);

  console.log("\n--- website/functions/api/_shared.js CAT_ADDRS_SEPOLIA ---");
  console.log(`[2] OverflowCat    = ${overflowCat.target}`);
  console.log(`[3] UnprotectedCat = ${unprotectedCat.target}`);
  console.log(`[4] MisspelledCat  = ${misspelledCat.target}`);

  console.log("\n--- verify (after a few confirmations) ---");
  console.log(`npx hardhat verify --network ${network.name} ${overflowCat.target}`);
  console.log(`npx hardhat verify --network ${network.name} ${unprotectedCat.target}`);
  console.log(`npx hardhat verify --network ${network.name} ${misspelledCat.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
