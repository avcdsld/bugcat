const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying BugCats v4 contracts to mainnet...");

  // 1. Deploy OverflowCat
  console.log("1. Deploying OverflowCat...");
  const OverflowCat = await ethers.getContractFactory("OverflowCat");
  const overflowCat = await OverflowCat.deploy();
  await overflowCat.waitForDeployment();
  console.log("OverflowCat deployed to:", overflowCat.target);

  // 2. Deploy UnprotectedCat
  console.log("2. Deploying UnprotectedCat...");
  const UnprotectedCat = await ethers.getContractFactory("UnprotectedCat");
  const unprotectedCat = await UnprotectedCat.deploy();
  await unprotectedCat.waitForDeployment();
  console.log("UnprotectedCat deployed to:", unprotectedCat.target);

  // 3. Deploy MisspelledCat (last)
  console.log("3. Deploying MisspelledCat...");
  const MisspelledCat = await ethers.getContractFactory("MisspelledCat");
  const misspelledCat = await MisspelledCat.deploy();
  await misspelledCat.waitForDeployment();
  console.log("MisspelledCat deployed to:", misspelledCat.target);

  console.log("\n=== v4 Deployment Complete ===");
  console.log("OverflowCat:", overflowCat.target);
  console.log("UnprotectedCat:", unprotectedCat.target);
  console.log("MisspelledCat:", misspelledCat.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });