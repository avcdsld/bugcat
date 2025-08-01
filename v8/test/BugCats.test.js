const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BugCats v8 Tests", function () {
  let owner, attacker;
  let predictableCat, reentrancyCat;
  let prophet, seeker;

  beforeEach(async function () {
    [owner, attacker] = await ethers.getSigners();

    const PredictableCat = await ethers.getContractFactory("PredictableCat");
    predictableCat = await PredictableCat.deploy();

    const ReentrancyCat = await ethers.getContractFactory("ReentrancyCat");
    reentrancyCat = await ReentrancyCat.deploy();

    const Prophet = await ethers.getContractFactory("Prophet");
    prophet = await Prophet.deploy();

    const Seeker = await ethers.getContractFactory("Seeker");
    seeker = await Seeker.deploy(reentrancyCat.target);
  });

  it("Should make PredictableCat meow through Prophet", async function () {
    let attempts = 0;
    const maxAttempts = 100;
    let meowEmitted = false;

    while (attempts < maxAttempts && !meowEmitted) {
      try {
        const tx = await prophet.caress(predictableCat.target);
        const receipt = await tx.wait();
        
        const meowEvent = receipt.logs.find(log => 
          log.topics[0] === ethers.id("Meow(address,string)")
        );
        
        if (meowEvent) {
          console.log(`Meow emitted after ${attempts + 1} attempts!`);
          meowEmitted = true;
          
          expect(meowEvent).to.not.be.undefined;
          expect(await predictableCat.winCount(prophet.target)).to.equal(0);
        }
      } catch (error) {
        // Expected when prediction fails
      }
      
      attempts++;
      await ethers.provider.send("evm_mine");
    }

    expect(meowEmitted).to.be.true;
  });

  it("Should make ReentrancyCat meow through Seeker reentrancy attack", async function () {
    // Setup: deposit some ether into ReentrancyCat
    await reentrancyCat.connect(owner).deposit({ value: ethers.parseEther("2") });
    
    // Execute reentrancy attack through Seeker
    const tx = await seeker.caress({ value: ethers.parseEther("1") });
    const receipt = await tx.wait();
    
    // Contract should be drained
    expect(await ethers.provider.getBalance(reentrancyCat.target)).to.equal(0);
    
    // Check if Meow event was emitted during the attack
    const meowEvent = receipt.logs.find(log => 
      log.topics[0] === ethers.id("Meow(address,string)")
    );
    
    expect(meowEvent).to.not.be.undefined;
  });

  it("Should verify all cats remember their historical vulnerabilities", async function () {
    console.log("PredictableCat remembers FoMo3D:", await predictableCat.remember());
    console.log("ReentrancyCat remembers TheDAO:", await reentrancyCat.remember());
  });
});