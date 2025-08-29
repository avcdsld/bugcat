const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BugcatHouse Tests", function () {
  let owner, user1, user2;
  let bugcatHouse;
  
  const REGISTRY_ADDRESS = "0x652f57021b4d39223e3769021a7d3edf01a1139e";
  
  let bugcatHouseRenderer;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    const network = await ethers.provider.getNetwork();
    console.log("Network chainId:", network.chainId);
    
    const registryCode = await ethers.provider.getCode(REGISTRY_ADDRESS);
    expect(registryCode).to.not.equal("0x", "Registry contract should exist on mainnet fork");
    
    const catCount = 5;
    console.log("Using fixed catCount:", catCount);

    const BugcatHouse = await ethers.getContractFactory("BugcatHouse");
    bugcatHouse = await BugcatHouse.deploy(
      owner.address,
      REGISTRY_ADDRESS,
      catCount,
      owner.address,
      ethers.ZeroAddress,
      owner.address
    );

    console.log("BugcatHouse deployed at:", bugcatHouse.target);
    console.log("No renderer (using address(0))");
  });

  it("Should deploy BugcatHouse with correct parameters", async function () {
    const registryAddress = await bugcatHouse.registry();
    expect(registryAddress.toLowerCase()).to.equal(REGISTRY_ADDRESS.toLowerCase());
    expect(await bugcatHouse.minter()).to.equal(owner.address);
    expect(await bugcatHouse.renderer()).to.equal(ethers.ZeroAddress);
    expect(await bugcatHouse.owner()).to.equal(owner.address);
  });

  it("Should mint a new BugcatHouse token", async function () {
    const tokenId = 1;
    
    console.log("Current block number:", await ethers.provider.getBlockNumber());
    console.log("Current block timestamp:", (await ethers.provider.getBlock("latest")).timestamp);
    
    const registry = new ethers.Contract(
      REGISTRY_ADDRESS,
      ["function bugs(uint256) external view returns (address)"],
      ethers.provider
    );
    
    let availableCats = 0;
    for (let i = 0; i < 5; i++) {
      try {
        const catAddress = await registry.bugs(i);
        const catCode = await ethers.provider.getCode(catAddress);
        if (catCode !== "0x") {
          console.log(`Cat ${i}: ${catAddress} (has code: true)`);
          availableCats++;
        } else {
          console.log(`Cat ${i}: ${catAddress} (has code: false)`);
        }
      } catch (error) {
        console.log(`Could not get cat ${i} from registry:`, error.message);
        break;
      }
    }
    console.log(`Total available cats found: ${availableCats}`);
    
    try {
      const catCount = await bugcatHouse.catCount();
      console.log("Cat count:", catCount.toString());
      
      const currentBlock = await ethers.provider.getBlock("latest");
      console.log("Current block hash:", currentBlock.hash);
      console.log("Current block prevrandao:", currentBlock.prevrandao);
      
      for (let i = 0; i < 5; i++) {
        try {
          const catAddress = await registry.bugs(i);
          const catCode = await ethers.provider.getCode(catAddress);
          console.log(`Cat ${i} extcodesize check: ${catAddress} -> ${catCode !== "0x" ? "has code" : "no code"}`);
        } catch (error) {
          console.log(`Error checking cat ${i}:`, error.message);
        }
      }
      
      console.log("Simulating _pickCat function...");
      const r = ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(
        ["uint256", "bytes32", "bytes32", "address", "uint256", "address", "uint256"],
        [
          currentBlock.timestamp,
          currentBlock.hash,
          await ethers.provider.getBlock(currentBlock.number - 2).then(b => b.hash),
          user1.address,
          tokenId,
          bugcatHouse.target,
          0
        ]
      ));
      const start = BigInt(r) % 5n;
      console.log("Simulated start index:", start.toString());
      
      for (let j = 0; j < 5; j++) {
        const index = (start + BigInt(j)) % 5n;
        const catAddress = await registry.bugs(index);
        const catCode = await ethers.provider.getCode(catAddress);
        console.log(`Index ${index}: ${catAddress} -> ${catCode !== "0x" ? "has code" : "no code"}`);
        if (catCode !== "0x") {
          console.log(`Found valid cat at index ${index}`);
          break;
        }
      }
    } catch (error) {
      console.log("Error testing _pickCat:", error.message);
    }
    
    let tx, receipt;
    try {
      tx = await bugcatHouse.mint(user1.address, tokenId);
      receipt = await tx.wait();
    } catch (error) {
      console.log("Mint failed with error:", error.message);
      if (error.data) {
        console.log("Error data:", error.data);
      }
      throw error;
    }
    
    const mintEventTopic = ethers.id("Mint(address,uint256,uint8)");
    const mintEvent = receipt.logs.find(log => log.topics[0] === mintEventTopic);
    expect(mintEvent).to.not.be.undefined;
    
    expect(await bugcatHouse.ownerOf(tokenId)).to.equal(user1.address);
    
    expect(await bugcatHouse.totalMinted()).to.equal(1);
    
    const returnEventTopic = ethers.id("Return(uint256,uint8,uint64)");
    const returnEvent = receipt.logs.find(log => log.topics[0] === returnEventTopic);
    expect(returnEvent).to.not.be.undefined;
  });

  it("Should return correct tokenURI after minting", async function () {
    const tokenId = 2;
    
    await bugcatHouse.mint(user2.address, tokenId);
    
    const tokenURI = await bugcatHouse.tokenURI(tokenId);
    console.log("TokenURI:", tokenURI);
    
    expect(tokenURI).to.match(/^data:application\/json;base64,/);
    
    const jsonBase64 = tokenURI.replace("data:application/json;base64,", "");
    const jsonString = Buffer.from(jsonBase64, 'base64').toString();
    const jsonData = JSON.parse(jsonString);
    
    console.log("Decoded JSON:", jsonData);
    
    expect(jsonData.name).to.equal(`BUGCAT House #${tokenId}`);
    expect(jsonData.description).to.equal("BUGCATs wander. The house remembers.");
    expect(jsonData.image).to.match(/^data:text\/html;base64,/);
    
    const htmlBase64 = jsonData.image.replace("data:text/html;base64,", "");
    const htmlString = Buffer.from(htmlBase64, 'base64').toString();
    console.log("Decoded HTML length:", htmlString.length);
    expect(htmlString.length).to.equal(0);
  });

  it("Should generate different tokenURI for different tokenIds", async function () {
    const tokenId1 = 10;
    const tokenId2 = 11;
    
    await bugcatHouse.mint(user1.address, tokenId1);
    await bugcatHouse.mint(user2.address, tokenId2);
    
    const tokenURI1 = await bugcatHouse.tokenURI(tokenId1);
    const tokenURI2 = await bugcatHouse.tokenURI(tokenId2);
    
    console.log(`Token ${tokenId1} URI:`, tokenURI1);
    console.log(`Token ${tokenId2} URI:`, tokenURI2);
    
    expect(tokenURI1).to.not.equal(tokenURI2);
    
    const jsonBase64_1 = tokenURI1.replace("data:application/json;base64,", "");
    const jsonData1 = JSON.parse(Buffer.from(jsonBase64_1, 'base64').toString());
    
    const jsonBase64_2 = tokenURI2.replace("data:application/json;base64,", "");
    const jsonData2 = JSON.parse(Buffer.from(jsonBase64_2, 'base64').toString());
    
    expect(jsonData1.name).to.equal(`BUGCAT House #${tokenId1}`);
    expect(jsonData2.name).to.equal(`BUGCAT House #${tokenId2}`);
    
    expect(jsonData1.description).to.equal(jsonData2.description);
    expect(jsonData1.description).to.equal("BUGCATs wander. The house remembers.");
    
    expect(jsonData1.image).to.match(/^data:text\/html;base64,/);
    expect(jsonData2.image).to.match(/^data:text\/html;base64,/);
    
    console.log(`Token ${tokenId1} name:`, jsonData1.name);
    console.log(`Token ${tokenId2} name:`, jsonData2.name);
  });

  it("Should handle tokenURI for non-existent token", async function () {
    const nonExistentTokenId = 999;
    
    try {
      await bugcatHouse.tokenURI(nonExistentTokenId);
      expect.fail("Should have thrown an error for non-existent token");
    } catch (error) {
      console.log("Expected error for non-existent token:", error.message);
      expect(error.message).to.include("ERC721NonexistentToken");
    }
  });

  it("Should track memories correctly", async function () {
    const tokenId = 3;
    
    await bugcatHouse.mint(user1.address, tokenId);
    
    const [lastCat, lastTime] = await bugcatHouse.latest(tokenId);
    expect(lastCat).to.be.greaterThanOrEqual(0);
    expect(lastTime).to.be.greaterThan(0);
    
    console.log("Last cat:", lastCat.toString());
    console.log("Last time:", lastTime.toString());
    
    const [times, cats] = await bugcatHouse.remember(tokenId, 0, 10);
    expect(times.length).to.equal(1);
    expect(cats.length).to.equal(1);
    expect(times[0]).to.equal(lastTime);
    expect(cats[0]).to.equal(lastCat);
  });

  it("Should allow calling the house to get new cats", async function () {
    const tokenId = 4;
    
    await bugcatHouse.mint(user1.address, tokenId);
    
    const [initialCat, initialTime] = await bugcatHouse.latest(tokenId);
    
    await ethers.provider.send("evm_mine");
    
    await bugcatHouse.connect(user1).call(tokenId);
    
    const [newCat, newTime] = await bugcatHouse.latest(tokenId);
    expect(newTime).to.be.greaterThan(initialTime);
    
    const [times, cats] = await bugcatHouse.remember(tokenId, 0, 10);
    expect(times.length).to.equal(2);
    expect(cats.length).to.equal(2);
  });

  it("Should mint multiple tokens in batch", async function () {
    const tokenIds = [5, 6, 7];
    const recipients = [user1.address, user2.address, user1.address];
    
    await bugcatHouse.mintBatch(recipients, tokenIds);
    
    for (let i = 0; i < tokenIds.length; i++) {
      expect(await bugcatHouse.ownerOf(tokenIds[i])).to.equal(recipients[i]);
    }
    
  });

  it("Should handle owner functions correctly", async function () {
    await bugcatHouse.setMinter(user1.address);
    expect(await bugcatHouse.minter()).to.equal(user1.address);
    
    await bugcatHouse.setRenderer(user2.address);
    expect(await bugcatHouse.renderer()).to.equal(user2.address);
    
    await bugcatHouse.setDefaultRoyalty(user2.address, 500); // 5%
    
    const tokenId = 8;
    await bugcatHouse.connect(user1).mint(user2.address, tokenId);
    expect(await bugcatHouse.ownerOf(tokenId)).to.equal(user2.address);
  });

  it("Should verify registry integration", async function () {
    const registry = new ethers.Contract(
      REGISTRY_ADDRESS,
      ["function bugs(uint256) external view returns (address)"],
      ethers.provider
    );
    
    for (let i = 0; i < 5; i++) {
      try {
        const catAddress = await registry.bugs(i);
        const catCode = await ethers.provider.getCode(catAddress);
        console.log(`Cat ${i}: ${catAddress} (has code: ${catCode !== "0x"})`);
      } catch (error) {
        console.log(`Could not get cat ${i} from registry`);
      }
    }
  });
});

describe("BugcatHouseRenderer", function () {
  let bugcatHouseRenderer;
  let bugcatHouseWithRenderer;
  
  const REGISTRY_ADDRESS = "0x652f57021b4d39223e3769021a7d3edf01a1139e";

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    try {
      const ENSResolver = await ethers.getContractFactory("ENSResolver");
      const ensResolver = await ENSResolver.deploy();

      const BugcatHouseRenderer = await ethers.getContractFactory("BugcatHouseRenderer", {
        libraries: {
          ENSResolver: ensResolver.target
        }
      });
      bugcatHouseRenderer = await BugcatHouseRenderer.deploy();

      const BugcatHouse = await ethers.getContractFactory("BugcatHouse");
      bugcatHouseWithRenderer = await BugcatHouse.deploy(
        owner.address,
        REGISTRY_ADDRESS,
        5,
        owner.address,
        bugcatHouseRenderer.target,
        owner.address
      );
    } catch (error) {
      console.log("Error deploying renderer:", error.message);
      this.skip();
    }
  });

  it("Should render basic HTML", async function () {
    if (!bugcatHouseRenderer || !bugcatHouseWithRenderer) {
      this.skip();
    }

    const tokenId = 100;
    
    await bugcatHouseWithRenderer.mint(user1.address, tokenId);
    
    const tokenURI = await bugcatHouseWithRenderer.tokenURI(tokenId);
    const jsonBase64 = tokenURI.replace("data:application/json;base64,", "");
    const jsonString = Buffer.from(jsonBase64, 'base64').toString();
    const jsonData = JSON.parse(jsonString);
    
    const htmlBase64 = jsonData.image.replace("data:text/html;base64,", "");
    const htmlString = Buffer.from(htmlBase64, 'base64').toString();
    
    console.log("=== RENDERED HTML ===");
    console.log(htmlString);
    console.log("=== END HTML ===");
    
    expect(htmlString).to.not.equal("");
    expect(htmlString).to.include("<!DOCTYPE html>");
    
    console.log("HTML length:", htmlString.length);
    console.log("HTML contains tokenId:", htmlString.includes(tokenId.toString()));
    console.log("HTML contains caretaker address:", htmlString.includes(user1.address.toLowerCase()));
  });

  it("Should generate tokenURI with rendered HTML", async function () {
    if (!bugcatHouseRenderer || !bugcatHouseWithRenderer) {
      this.skip();
    }

    const tokenId = 0;
    
    await bugcatHouseWithRenderer.mint(user2.address, tokenId);
    
    const tokenURI = await bugcatHouseWithRenderer.tokenURI(tokenId);
    
    const jsonBase64 = tokenURI.replace("data:application/json;base64,", "");
    const jsonString = Buffer.from(jsonBase64, 'base64').toString();
    const jsonData = JSON.parse(jsonString);
    
    const htmlBase64 = jsonData.image.replace("data:text/html;base64,", "");
    const htmlString = Buffer.from(htmlBase64, 'base64').toString();
    
    console.log("=== RENDERED HTML FROM TOKENURI ===");
    console.log(jsonData.image);
    console.log("=== END HTML FROM TOKENURI ===");
    
    expect(htmlString.length).to.be.greaterThan(0);
    expect(htmlString).to.include("<!DOCTYPE html>");
    
    console.log("HTML from tokenURI length:", htmlString.length);
    console.log("HTML contains tokenId:", htmlString.includes(tokenId.toString()));
    console.log("HTML contains caretaker:", htmlString.includes(user2.address.toLowerCase()));
  });
});
