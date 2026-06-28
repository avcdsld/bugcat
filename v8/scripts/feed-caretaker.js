const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Feeds cats 2/3/4 through the Caretaker helper exactly as website/functions/api/caress.js does,
// and asserts each Meow landed. Reads addresses from deployment-<network>.json (written by
// deploy-mainnet-helpers.js). Each caress is a single atomic tx, so unlike the old direct-exploit
// path it always meows — including OverflowCat, which no longer re-overflows to zero.
//   cat 2 OverflowCat   : Caretaker.overflow(cat)
//   cat 3 UnprotectedCat: Caretaker.claim(cat)
//   cat 4 MisspelledCat : Caretaker.rename(cat)
const MEOW_TOPIC = ethers.id("Meow(address,string)");
const meowed = (receipt) => receipt.logs.some((l) => l.topics[0] === MEOW_TOPIC);

async function main() {
  const file = path.join(__dirname, "..", `deployment-${network.name}.json`);
  const addr = JSON.parse(fs.readFileSync(file, "utf8"));
  if (!addr.Caretaker) throw new Error(`Caretaker missing in ${file}`);

  const [signer] = await ethers.getSigners();
  console.log(`Feeding cats 2/3/4 via Caretaker on ${network.name} as ${signer.address}\n`);
  const c = await ethers.getContractAt("Caretaker", addr.Caretaker);

  const steps = [
    { i: 2, name: "OverflowCat", fn: "overflow", cat: addr.OverflowCat },
    { i: 3, name: "UnprotectedCat", fn: "claim", cat: addr.UnprotectedCat },
    { i: 4, name: "MisspelledCat", fn: "rename", cat: addr.MisspelledCat },
  ];

  for (const s of steps) {
    if (!s.cat) throw new Error(`${s.name} address missing in ${file}`);
    console.log(`cat ${s.i} ${s.name}: Caretaker.${s.fn}(${s.cat})`);
    const rc = await (await c[s.fn](s.cat, { gasLimit: 300000n })).wait();
    const ok = meowed(rc);
    console.log(`  tx ${rc.hash}  Meow=${ok}`);
    if (!ok) throw new Error(`${s.name} did not Meow`);
  }

  console.log("\n✅ cats 2/3/4 fed via Caretaker.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
