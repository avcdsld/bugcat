const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Starting ENSResolver library deployment to Base mainnet...");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying library with account:", deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // Deploy ENSResolver library
  console.log("\n📦 Deploying ENSResolver library...");
  const ENSResolver = await ethers.getContractFactory("ENSResolver");
  
  const library = await ENSResolver.deploy();
  await library.waitForDeployment();
  
  const libraryAddress = await library.getAddress();
  console.log("✅ ENSResolver library deployed to:", libraryAddress);

  // Summary
  console.log("\n🎉 Library Deployment Summary:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("📋 ENSResolver Library:", libraryAddress);
  console.log("🌐 Network: Base Mainnet (Chain ID: 8453)");
  console.log("👤 Deployer:", deployer.address);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  // Save deployment info
  const deploymentInfo = {
    network: "base",
    chainId: 8453,
    deployer: deployer.address,
    contracts: {
      ENSResolver: libraryAddress
    },
    timestamp: new Date().toISOString()
  };

  const fs = require('fs');
  fs.writeFileSync(
    './deployment-base-library.json', 
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log("💾 Library deployment info saved to deployment-base-library.json");
  console.log("\n⚠️  IMPORTANT: Update hardhat.config.js with this library address before deploying main contracts!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Library deployment failed:", error);
    process.exit(1);
  });
