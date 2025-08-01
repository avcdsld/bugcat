const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying BUGCATS manager contract...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy BUGCATS
  console.log("\nDeploying BUGCATS...");
  const BUGCATS = await ethers.getContractFactory("BUGCATS");
  const bugcats = await BUGCATS.deploy(deployer.address);
  
  console.log("Waiting for deployment confirmation...");
  await bugcats.waitForDeployment();
  
  console.log("\n🐱 BUGCATS deployed successfully!");
  console.log("Contract address:", bugcats.target);
  console.log("Owner:", await bugcats.owner());
  console.log("Current bugs count:", await bugcats.bugs.length || 0);

  console.log("\n=== Contract Verification ===");
  console.log(`npx hardhat verify --network mainnet ${bugcats.target} "${deployer.address}"`);
  
  console.log("\n=== Next Steps ===");
  console.log("To inject bug contracts:");
  console.log(`bugcats.inject("<cat_contract_address>")`);
  
  console.log("\n=== Remember Function ===");
  console.log("To check if a bug remembers:");
  console.log(`bugcats.remember(<index>)`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 