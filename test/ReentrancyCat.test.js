const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ReentrancyCat", function () {
  let cat;
  let render;
  let minter;
  let daoMock;
  let alice;

  beforeEach(async function () {
    [alice] = await ethers.getSigners();

    const TheDAOMock = await ethers.getContractFactory("TheDAOMock");
    daoMock = await TheDAOMock.deploy();
    const daoMockAddress = await daoMock.getAddress();

    const Render = await ethers.getContractFactory("Render");
    render = await Render.deploy(daoMockAddress);
    const renderAddress = await render.getAddress();

    const ReentrancyCat = await ethers.getContractFactory("ReentrancyCat");
    cat = await ReentrancyCat.deploy(renderAddress);

    const Minter = await ethers.getContractFactory("Minter");
    minter = await Minter.deploy(await cat.getAddress());
  });

  it("should mint and return tokenURI", async function () {
    await cat.connect(alice).mint(alice.address);
    const tokenURI = await cat.tokenURI(0);
    console.log("TokenURI (normal mint):", tokenURI);
    
    const base64Data = tokenURI.replace("data:application/json;base64,", "");
    const jsonStr = Buffer.from(base64Data, "base64").toString();
    const json = JSON.parse(jsonStr);
    
    console.log("Decoded JSON (normal mint):", json);
    expect(json.name).to.equal("ReentrancyCat #0");

    const svgBase64 = json.image.replace("data:image/svg+xml;base64,", "");
    const svg = Buffer.from(svgBase64, "base64").toString();
    expect(svg).to.include("lonely, so lonely");
  });

  it("should mint via glitch and return tokenURIs", async function () {
    await minter.connect(alice).mint(alice.address);
    // glitchで複数ミントされる想定
    const balance = await cat.balanceOf(alice.address);
    // expect(balance).to.equal(2);

    for (let i = 0; i < 1; i++) {
      const tokenURI = await cat.tokenURI(i);
      console.log(`TokenURI (glitch mint, token ${i}):`, tokenURI);

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
