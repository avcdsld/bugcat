const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Redeploys ONLY the Seeker helper against the already-deployed ReentrancyCat, and updates the
// Seeker address in deployment-<network>.json. Use after changing Seeker.sol (e.g. the auto-refund
// fix) so the cats / Prophet stay put and only SEEKER_ADDR needs updating on Cloudflare.
async function main() {
  const file = path.join(__dirname, "..", `deployment-${network.name}.json`);
  const addr = JSON.parse(fs.readFileSync(file, "utf8"));
  if (!addr.ReentrancyCat) throw new Error(`ReentrancyCat missing in ${file}`);

  const [deployer] = await ethers.getSigners();
  console.log(`Redeploying Seeker on ${network.name} as ${deployer.address}`);
  console.log(`ReentrancyCat (unchanged): ${addr.ReentrancyCat}`);

  const seeker = await (await ethers.getContractFactory("Seeker")).deploy(addr.ReentrancyCat);
  await seeker.waitForDeployment();
  console.log("new Seeker:", seeker.target);

  addr.Seeker = seeker.target;
  fs.writeFileSync(file, JSON.stringify(addr, null, 2) + "\n");

  console.log("\n--- update on Cloudflare Pages ---");
  console.log(`SEEKER_ADDR = ${seeker.target}`);
  console.log("\n--- verify ---");
  console.log(`npx hardhat verify --network ${network.name} ${seeker.target} ${addr.ReentrancyCat}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
