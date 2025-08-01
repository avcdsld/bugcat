const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying BugCats v8 contracts to mainnet...");

  // 1. Deploy ReentrancyCat
  console.log("1. Deploying ReentrancyCat...");
  const ReentrancyCat = await ethers.getContractFactory("ReentrancyCat");
  const reentrancyCat = await ReentrancyCat.deploy();
  await reentrancyCat.waitForDeployment();
  console.log("ReentrancyCat deployed to:", reentrancyCat.target);

  // 2. Deploy Seeker (needs ReentrancyCat address)
  console.log("2. Deploying Seeker...");
  const Seeker = await ethers.getContractFactory("Seeker");
  const seeker = await Seeker.deploy(reentrancyCat.target);
  await seeker.waitForDeployment();
  console.log("Seeker deployed to:", seeker.target);

  // 3. Deploy PredictableCat
  console.log("3. Deploying PredictableCat...");
  const PredictableCat = await ethers.getContractFactory("PredictableCat");
  const predictableCat = await PredictableCat.deploy();
  await predictableCat.waitForDeployment();
  console.log("PredictableCat deployed to:", predictableCat.target);

  // 4. Deploy Prophet
  console.log("4. Deploying Prophet...");
  const Prophet = await ethers.getContractFactory("Prophet");
  const prophet = await Prophet.deploy();
  await prophet.waitForDeployment();
  console.log("Prophet deployed to:", prophet.target);

  console.log("\n=== v8 Deployment Complete ===");
  console.log("ReentrancyCat:", reentrancyCat.target);
  console.log("Seeker:", seeker.target);
  console.log("PredictableCat:", predictableCat.target);
  console.log("Prophet:", prophet.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });