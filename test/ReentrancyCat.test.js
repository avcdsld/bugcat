const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ReentrancyCat", function () {
  let cat;
  let alice;
  let bob;

  beforeEach(async function () {
    [alice, bob] = await ethers.getSigners();
    const ReentrancyCat = await ethers.getContractFactory("ReentrancyCat");
    cat = await ReentrancyCat.deploy();
  });

  it("should fail on normal mint", async function () {
    await expect(cat.connect(alice).mint()).to.be.reverted;
  });

  it("should mint 2 tokens with glitch", async function () {
    await cat.connect(alice).glitch();
    const balance = await cat.balanceOf(alice.address);
    expect(balance).to.equal(2);
  });

  // it("should mint 2 tokens with Minter", async function () {
  //   const Minter = await ethers.getContractFactory("Minter");
  //   const minter = await Minter.deploy(await cat.getAddress());

  //   await minter.connect(alice).mint(alice.address);
  //   const balance = await cat.balanceOf(alice.address);
  //   expect(balance).to.equal(2);
  // });
}); 