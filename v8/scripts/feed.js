const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Feeds the v8 cats so each lets out a Meow, mirroring website/functions/api/caress.js exactly,
// and asserts the Meow event landed. Reads addresses from deployment-<network>.json.
//   cat 0 ReentrancyCat : Seeker.caress{value}() -> deposit -> withdraw -> reenter -> caress()
//   cat 1 PredictableCat: Prophet.caress(cat) (block-prediction gated) -> flip x10 -> caress()
const MEOW_TOPIC = ethers.id("Meow(address,string)");
const SEEKER_VALUE = process.env.SEEKER_VALUE ? BigInt(process.env.SEEKER_VALUE) : 1n;
const PREDICTABLE_RETRIES = 8;

const meowed = (receipt) => receipt.logs.some((l) => l.topics[0] === MEOW_TOPIC);

async function main() {
  const file = path.join(__dirname, "..", `deployment-${network.name}.json`);
  const addr = JSON.parse(fs.readFileSync(file, "utf8"));
  const [signer] = await ethers.getSigners();
  console.log(`Feeding v8 cats on ${network.name} as ${signer.address}\n`);

  // --- cat 0: ReentrancyCat via Seeker ---
  const seeker = await ethers.getContractAt("Seeker", addr.Seeker);
  console.log(`cat 0 ReentrancyCat: Seeker.caress{value: ${SEEKER_VALUE}}()`);
  let rc = await (await seeker.caress({ value: SEEKER_VALUE })).wait();
  console.log(`  tx ${rc.hash}  Meow=${meowed(rc)}`);
  if (!meowed(rc)) throw new Error("ReentrancyCat did not Meow");

  // --- cat 1: PredictableCat via Prophet (≈50% per tx, retry) ---
  const prophet = await ethers.getContractAt("Prophet", addr.Prophet);
  console.log(`cat 1 PredictableCat: Prophet.caress(${addr.PredictableCat})`);
  let ok = false;
  for (let i = 0; i < PREDICTABLE_RETRIES && !ok; i++) {
    rc = await (await prophet.caress(addr.PredictableCat)).wait();
    ok = meowed(rc);
    console.log(`  try ${i + 1}: tx ${rc.hash}  Meow=${ok}`);
  }
  if (!ok) throw new Error(`PredictableCat did not Meow after ${PREDICTABLE_RETRIES} tries`);

  console.log("\n✅ v8 cats fed (ReentrancyCat, PredictableCat).");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
