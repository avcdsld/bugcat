const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ReentrancyCat", function () {
  let cat;
  let alice;

  beforeEach(async function () {
    [alice] = await ethers.getSigners();
    const ReentrancyCat = await ethers.getContractFactory("ReentrancyCat");
    cat = await ReentrancyCat.deploy();
  });

  it("should mint and return tokenURI", async function () {
    await cat.connect(alice).mint(alice.address);
    const tokenURI = await cat.tokenURI(0);
    console.log("TokenURI (normal mint):", tokenURI);
    
    // Base64デコード
    const base64Data = tokenURI.replace("data:application/json;base64,", "");
    const jsonStr = Buffer.from(base64Data, "base64").toString();
    const json = JSON.parse(jsonStr);
    
    console.log("Decoded JSON (normal mint):", json);
    expect(json.name).to.equal("ReentrancyCat #0");
  });

  it("should mint via glitch and return tokenURIs", async function () {
    await cat.connect(alice).glitch();
    // glitchで2つミントされる想定
    const balance = await cat.balanceOf(alice.address);
    // expect(balance).to.equal(2);

    for (let i = 0; i < 2; i++) {
      const tokenURI = await cat.tokenURI(i);
      console.log(`TokenURI (glitch mint, token ${i}):`, tokenURI);
      
      // Base64デコード
      const base64Data = tokenURI.replace("data:application/json;base64,", "");
      const jsonStr = Buffer.from(base64Data, "base64").toString();
      const json = JSON.parse(jsonStr);
      
      console.log(`Decoded JSON (glitch mint, token ${i}):`, json);
      expect(json.name).to.equal(`ReentrancyCat #${i}`);

      const owner = await cat.ownerOf(i);
      console.log(`ownerOf tokenId ${i}:`, owner);
    }
  });
}); 