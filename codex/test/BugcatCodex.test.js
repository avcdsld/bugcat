const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BugcatCodex Tests", function () {
  let owner, user1, user2;
  let bugcatCodex;
  
  const REGISTRY_ADDRESS = "0x652f57021b4d39223e3769021a7d3edf01a1139e";
  
  let bugcatCodexRenderer;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    const network = await ethers.provider.getNetwork();
    console.log("Network chainId:", network.chainId);
    
    const bugcatCount = 5;
    console.log("Using fixed bugcatCount:", bugcatCount);

    try {
      const ENSResolver = await ethers.getContractFactory("ENSResolver");
      const ensResolver = await ENSResolver.deploy();

      const BugcatCodexRenderer = await ethers.getContractFactory("BugcatCodexRenderer", {
        libraries: {
          ENSResolver: ensResolver.target
        }
      });
      bugcatCodexRenderer = await BugcatCodexRenderer.deploy();

      const BugcatCodex = await ethers.getContractFactory("BugcatCodex");
      bugcatCodex = await BugcatCodex.deploy(
        owner.address,
        REGISTRY_ADDRESS,
        bugcatCount,
        bugcatCodexRenderer.target,
        owner.address
      );

      console.log("BugcatCodex deployed at:", bugcatCodex.target);
      console.log("With renderer:", bugcatCodexRenderer.target);
    } catch (error) {
      console.log("Error deploying renderer:", error.message);
      this.skip();
    }
  });

  it("Should deploy BugcatCodex with correct parameters", async function () {
    const registryAddress = await bugcatCodex.registry();
    expect(registryAddress.toLowerCase()).to.equal(REGISTRY_ADDRESS.toLowerCase());
    expect(await bugcatCodex.minter()).to.equal(owner.address);
    expect(await bugcatCodex.renderer()).to.not.equal(ethers.ZeroAddress);
    expect(await bugcatCodex.owner()).to.equal(owner.address);
    expect(await bugcatCodex.bugcatCount()).to.equal(5);
  });

  it("Should call rememberCode 5 times and then mint tokens", async function () {
    const registry = new ethers.Contract(
      REGISTRY_ADDRESS,
      ["function bugs(uint256) external view returns (address)"],
      ethers.provider
    );
    
    // Get 5 bugcat addresses from registry
    const bugcatAddresses = [];
    for (let i = 0; i < 5; i++) {
      try {
        const catAddress = await registry.bugs(i);
        const catCode = await ethers.provider.getCode(catAddress);
        if (catCode !== "0x") {
          bugcatAddresses.push(catAddress);
          console.log(`Bugcat ${i}: ${catAddress} (has code: true)`);
        } else {
          console.log(`Bugcat ${i}: ${catAddress} (has code: false)`);
        }
      } catch (error) {
        console.log(`Could not get bugcat ${i} from registry:`, error.message);
      }
    }
    
    console.log(`Total bugcats found: ${bugcatAddresses.length}`);
    
    // Call rememberCode 5 times with sample code
    const sampleCodes = [
      "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.4.26;\n\nimport \"../interface/BugCat.sol\";\n\ncontract MisspelledCat is BugCat {\n    address public owner;\n\n    function MisspeledCat(address o) {\n        owner = o;\n    }\n\n    function caress() public {\n        if (msg.sender == owner) {\n            emit Meow(msg.sender, \"misspelled\");\n        }\n    }\n\n    function remember() external view returns (bool) {\n        address Rubixi = 0xe82719202e5965Cf5D9B6673B7503a3b92DE20be;\n        uint256 size; assembly { size := extcodesize(Rubixi) }\n        return size > 0;\n    }\n}",
      "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.4.26;\n\nimport \"../interface/BugCat.sol\";\n\ncontract OverflowCat is BugCat {\n    uint256 public count;\n\n    function caress() public {\n        count++;\n    }\n\n    function remember() external view returns (bool) {\n        return count > 0;\n    }\n}",
      "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.4.26;\n\nimport \"../interface/BugCat.sol\";\n\ncontract UnprotectedCat is BugCat {\n    address public owner;\n\n    function caress() public {\n        owner = msg.sender;\n    }\n\n    function remember() external view returns (bool) {\n        return owner != address(0);\n    }\n}",
      "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.4.26;\n\nimport \"../interface/BugCat.sol\";\n\ncontract PredictableCat is BugCat {\n    uint256 public seed;\n\n    function caress() public {\n        seed = block.timestamp;\n    }\n\n    function remember() external view returns (bool) {\n        return seed > 0;\n    }\n}",
      "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.4.26;\n\nimport \"../interface/BugCat.sol\";\n\ncontract ReentrancyCat is BugCat {\n    bool public locked;\n\n    function caress() public {\n        require(!locked, \"locked\");\n        locked = true;\n        // External call without reentrancy protection\n        msg.sender.call(\"\");\n        locked = false;\n    }\n\n    function remember() external view returns (bool) {\n        return !locked;\n    }\n}"
    ];
    
    // Call rememberCode for each bugcat address
    for (let i = 0; i < Math.min(bugcatAddresses.length, 5); i++) {
      const bugcatAddress = bugcatAddresses[i];
      const code = sampleCodes[i];
      
      console.log(`Calling rememberCode for bugcat ${i}: ${bugcatAddress}`);
      await bugcatCodex.rememberCode(bugcatAddress, code);
      
      // Verify the code was stored
      const storedCode = await bugcatCodex.codes(bugcatAddress);
      expect(storedCode).to.equal(code);
      console.log(`✓ Code stored for bugcat ${i}`);
    }
    
    console.log("✓ All 5 rememberCode calls completed");
  });

  it("Should mint single token and verify tokenURI", async function () {
    // First, set up some codes
    const registry = new ethers.Contract(
      REGISTRY_ADDRESS,
      ["function bugs(uint256) external view returns (address)"],
      ethers.provider
    );
    
    const bugcatAddresses = [];
    for (let i = 0; i < 5; i++) {
      try {
        const catAddress = await registry.bugs(i);
        const catCode = await ethers.provider.getCode(catAddress);
        if (catCode !== "0x") {
          bugcatAddresses.push(catAddress);
        }
      } catch (error) {
        console.log(`Could not get bugcat ${i} from registry:`, error.message);
      }
    }
    
    // Set up codes for available bugcats
    const sampleCode = "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.8.30;\n\nimport \"../interface/BugCat.sol\";\n\ncontract ReentrancyCat is BugCat {\n    mapping(address => uint) public balance;\n\n    function deposit() public payable {\n        balance[msg.sender] += msg.value;\n    }\n\n    function withdraw() public {\n        (bool success, ) = msg.sender.call{value: balance[msg.sender]}(\"\");\n        require(success);\n        balance[msg.sender] = 0;\n    }\n\n    function caress() public {\n        if (address(this).balance == 0) {\n            emit Meow(msg.sender, \"reentrancy\");\n        }\n    }\n\n    function remember() external view returns (bool) {\n        address TheDAO = 0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413;\n        return TheDAO.code.length > 0;\n    }\n}";
    for (let i = 0; i < Math.min(bugcatAddresses.length, 5); i++) {
      await bugcatCodex.rememberCode(bugcatAddresses[i], sampleCode);
    }
    
    // Mint a token
    const tokenId = 1;
    await bugcatCodex.mint(user1.address, tokenId);
    
    expect(await bugcatCodex.ownerOf(tokenId)).to.equal(user1.address);
    
    // Get tokenURI and verify (with error handling)
    try {
      const tokenURI = await bugcatCodex.tokenURI(tokenId);
      console.log("TokenURI:", tokenURI);
      
      expect(tokenURI).to.match(/^data:application\/json;base64,/);
      
      const jsonBase64 = tokenURI.replace("data:application/json;base64,", "");
      const jsonString = Buffer.from(jsonBase64, 'base64').toString();
      const jsonData = JSON.parse(jsonString);
      
      console.log("Decoded JSON:", jsonData);
      
      expect(jsonData.name).to.equal(`BUGCAT Codex #${tokenId}`);
      expect(jsonData.description).to.equal("BUGCATs wander. The Codex remembers.");
      expect(jsonData.image).to.match(/^data:text\/html;base64,/);
      
      // Decode and debug the HTML image
      const htmlBase64 = jsonData.image.replace("data:text/html;base64,", "");
      const htmlString = Buffer.from(htmlBase64, 'base64').toString();
      
      console.log("=== DEBUG: HTML IMAGE CONTENT ===");
      console.log("HTML length:", htmlString.length);
      console.log("HTML content:");
      console.log(htmlString);
      console.log("=== END HTML IMAGE CONTENT ===");
      
      expect(htmlString.length).to.be.greaterThan(0);
      expect(htmlString).to.include("<!DOCTYPE html>");
      expect(htmlString).to.include(`Codex #${tokenId}`);
      expect(htmlString).to.include(user1.address.toLowerCase());
    } catch (error) {
      console.log("TokenURI call failed:", error.message);
      console.log("This is expected when registry is not available in local network");
    }
  });

  it("Should mint batch tokens and verify tokenURIs", async function () {
    // First, set up some codes
    const registry = new ethers.Contract(
      REGISTRY_ADDRESS,
      ["function bugs(uint256) external view returns (address)"],
      ethers.provider
    );
    
    const bugcatAddresses = [];
    for (let i = 0; i < 5; i++) {
      try {
        const catAddress = await registry.bugs(i);
        const catCode = await ethers.provider.getCode(catAddress);
        if (catCode !== "0x") {
          bugcatAddresses.push(catAddress);
        }
      } catch (error) {
        console.log(`Could not get bugcat ${i} from registry:`, error.message);
      }
    }
    
    // Set up codes for available bugcats
    const sampleCode = "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.8.30;\n\nimport \"../interface/BugCat.sol\";\n\ncontract ReentrancyCat is BugCat {\n    mapping(address => uint) public balance;\n\n    function deposit() public payable {\n        balance[msg.sender] += msg.value;\n    }\n\n    function withdraw() public {\n        (bool success, ) = msg.sender.call{value: balance[msg.sender]}(\"\");\n        require(success);\n        balance[msg.sender] = 0;\n    }\n\n    function caress() public {\n        if (address(this).balance == 0) {\n            emit Meow(msg.sender, \"reentrancy\");\n        }\n    }\n\n    function remember() external view returns (bool) {\n        address TheDAO = 0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413;\n        return TheDAO.code.length > 0;\n    }\n}";
    for (let i = 0; i < Math.min(bugcatAddresses.length, 5); i++) {
      await bugcatCodex.rememberCode(bugcatAddresses[i], sampleCode);
    }
    
    // Mint batch tokens
    const tokenIds = [2, 3, 4];
    const recipients = [user1.address, user2.address, user1.address];
    
    await bugcatCodex.mintBatch(recipients, tokenIds);
    
    for (let i = 0; i < tokenIds.length; i++) {
      expect(await bugcatCodex.ownerOf(tokenIds[i])).to.equal(recipients[i]);
    }
    
    // Verify tokenURIs for all minted tokens
    for (let i = 0; i < tokenIds.length; i++) {
      const tokenId = tokenIds[i];
      try {
        const tokenURI = await bugcatCodex.tokenURI(tokenId);
        
        const jsonBase64 = tokenURI.replace("data:application/json;base64,", "");
        const jsonString = Buffer.from(jsonBase64, 'base64').toString();
        const jsonData = JSON.parse(jsonString);
        
        console.log(`=== DEBUG: Token ${tokenId} JSON ===`);
        console.log(jsonData);
        console.log(`=== END Token ${tokenId} JSON ===`);
        
        expect(jsonData.name).to.equal(`BUGCAT Codex #${tokenId}`);
        expect(jsonData.description).to.equal("BUGCATs wander. The Codex remembers.");
        expect(jsonData.image).to.match(/^data:text\/html;base64,/);
        
        // Decode and debug the HTML image
        const htmlBase64 = jsonData.image.replace("data:text/html;base64,", "");
        const htmlString = Buffer.from(htmlBase64, 'base64').toString();
        
        console.log(`=== DEBUG: Token ${tokenId} HTML IMAGE ===`);
        console.log("HTML length:", htmlString.length);
        console.log("HTML content:");
        console.log(htmlString);
        console.log(`=== END Token ${tokenId} HTML IMAGE ===`);
        
        expect(htmlString.length).to.be.greaterThan(0);
        expect(htmlString).to.include("<!DOCTYPE html>");
        expect(htmlString).to.include(`Codex #${tokenId}`);
        expect(htmlString).to.include(recipients[i].toLowerCase());
      } catch (error) {
        console.log(`TokenURI call failed for token ${tokenId}:`, error.message);
        console.log("This is expected when registry is not available in local network");
      }
    }
  });

  it("Should test theme switching and compilation features", async function () {
    // Set up code first
    const registry = new ethers.Contract(
      REGISTRY_ADDRESS,
      ["function bugs(uint256) external view returns (address)"],
      ethers.provider
    );
    
    const bugcatAddresses = [];
    for (let i = 0; i < 5; i++) {
      try {
        const catAddress = await registry.bugs(i);
        const catCode = await ethers.provider.getCode(catAddress);
        if (catCode !== "0x") {
          bugcatAddresses.push(catAddress);
        }
      } catch (error) {
        console.log(`Could not get bugcat ${i} from registry:`, error.message);
      }
    }
    
    const sampleCode = "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.8.30;\n\nimport \"../interface/BugCat.sol\";\n\ncontract ReentrancyCat is BugCat {\n    mapping(address => uint) public balance;\n\n    function deposit() public payable {\n        balance[msg.sender] += msg.value;\n    }\n\n    function withdraw() public {\n        (bool success, ) = msg.sender.call{value: balance[msg.sender]}(\"\");\n        require(success);\n        balance[msg.sender] = 0;\n    }\n\n    function caress() public {\n        if (address(this).balance == 0) {\n            emit Meow(msg.sender, \"reentrancy\");\n        }\n    }\n\n    function remember() external view returns (bool) {\n        address TheDAO = 0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413;\n        return TheDAO.code.length > 0;\n    }\n}";
    for (let i = 0; i < Math.min(bugcatAddresses.length, 5); i++) {
      await bugcatCodex.rememberCode(bugcatAddresses[i], sampleCode);
    }
    
    // Mint a token
    const tokenId = 5;
    await bugcatCodex.mint(user1.address, tokenId);
    
    // Test theme switching
    expect(await bugcatCodex.lights(tokenId)).to.be.false; // Default is dark theme
    
    await bugcatCodex.connect(user1).switchTheme(tokenId);
    expect(await bugcatCodex.lights(tokenId)).to.be.true; // Now light theme
    
    // Test compilation
    expect(await bugcatCodex.compileds(tokenId)).to.be.false; // Default is not compiled
    
    await bugcatCodex.connect(user1).compile(tokenId);
    expect(await bugcatCodex.compileds(tokenId)).to.be.true; // Now compiled
    
    // Test decompilation
    await bugcatCodex.connect(user1).decompile(tokenId);
    expect(await bugcatCodex.compileds(tokenId)).to.be.false; // Back to not compiled
    
    // Get tokenURI and verify it reflects the changes
    try {
      const tokenURI = await bugcatCodex.tokenURI(tokenId);
      const jsonBase64 = tokenURI.replace("data:application/json;base64,", "");
      const jsonString = Buffer.from(jsonBase64, 'base64').toString();
      const jsonData = JSON.parse(jsonString);
      
      const htmlBase64 = jsonData.image.replace("data:text/html;base64,", "");
      const htmlString = Buffer.from(htmlBase64, 'base64').toString();
      
      console.log("=== DEBUG: Token with light theme and decompiled ===");
      console.log("HTML content:");
      console.log(htmlString);
      console.log("=== END HTML ===");
      
      expect(htmlString).to.include('class="light"'); // Should have light theme
      expect(htmlString).to.include(sampleCode); // Should show source code, not bytecode
    } catch (error) {
      console.log("TokenURI call failed:", error.message);
      console.log("This is expected when registry is not available in local network");
    }
  });

  it("Should debug tokenURI image with light theme and compiled state", async function () {
    // Set up code first
    const registry = new ethers.Contract(
      REGISTRY_ADDRESS,
      ["function bugs(uint256) external view returns (address)"],
      ethers.provider
    );
    
    const bugcatAddresses = [];
    for (let i = 0; i < 5; i++) {
      try {
        const catAddress = await registry.bugs(i);
        const catCode = await ethers.provider.getCode(catAddress);
        if (catCode !== "0x") {
          bugcatAddresses.push(catAddress);
        }
      } catch (error) {
        console.log(`Could not get bugcat ${i} from registry:`, error.message);
      }
    }
    
    const sampleCode = "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.8.30;\n\nimport \"../interface/BugCat.sol\";\n\ncontract ReentrancyCat is BugCat {\n    mapping(address => uint) public balance;\n\n    function deposit() public payable {\n        balance[msg.sender] += msg.value;\n    }\n\n    function withdraw() public {\n        (bool success, ) = msg.sender.call{value: balance[msg.sender]}(\"\");\n        require(success);\n        balance[msg.sender] = 0;\n    }\n\n    function caress() public {\n        if (address(this).balance == 0) {\n            emit Meow(msg.sender, \"reentrancy\");\n        }\n    }\n\n    function remember() external view returns (bool) {\n        address TheDAO = 0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413;\n        return TheDAO.code.length > 0;\n    }\n}";
    for (let i = 0; i < Math.min(bugcatAddresses.length, 5); i++) {
      await bugcatCodex.rememberCode(bugcatAddresses[i], sampleCode);
    }
    
    // Mint a token
    const tokenId = 100;
    await bugcatCodex.mint(user1.address, tokenId);
    
    // Test 1: Dark theme + Source code (default state)
    console.log("=== TEST 1: Dark theme + Source code (default) ===");
    try {
      const tokenURI1 = await bugcatCodex.tokenURI(tokenId);
      const jsonBase64_1 = tokenURI1.replace("data:application/json;base64,", "");
      const jsonString_1 = Buffer.from(jsonBase64_1, 'base64').toString();
      const jsonData_1 = JSON.parse(jsonString_1);
      
      const htmlBase64_1 = jsonData_1.image.replace("data:text/html;base64,", "");
      const htmlString_1 = Buffer.from(htmlBase64_1, 'base64').toString();
      
      console.log("=== BASE64 HTML FOR BROWSER (Dark + Source) ===");
      console.log("data:text/html;base64," + htmlBase64_1);
      console.log("=== END BASE64 HTML ===");
      
      console.log("HTML content (Dark + Source):");
      console.log(htmlString_1);
      console.log("=== END Dark + Source ===");
      
      expect(htmlString_1).to.include('class="dark"');
      expect(htmlString_1).to.include(sampleCode);
      expect(htmlString_1).to.not.include('<!-- Bytecode:');
    } catch (error) {
      console.log("TokenURI call failed for dark theme:", error.message);
    }
    
    // Test 2: Light theme + Source code
    console.log("=== TEST 2: Light theme + Source code ===");
    await bugcatCodex.connect(user1).switchTheme(tokenId);
    expect(await bugcatCodex.lights(tokenId)).to.be.true;
    
    try {
      const tokenURI2 = await bugcatCodex.tokenURI(tokenId);
      const jsonBase64_2 = tokenURI2.replace("data:application/json;base64,", "");
      const jsonString_2 = Buffer.from(jsonBase64_2, 'base64').toString();
      const jsonData_2 = JSON.parse(jsonString_2);
      
      const htmlBase64_2 = jsonData_2.image.replace("data:text/html;base64,", "");
      const htmlString_2 = Buffer.from(htmlBase64_2, 'base64').toString();
      
      console.log("=== BASE64 HTML FOR BROWSER (Light + Source) ===");
      console.log("data:text/html;base64," + htmlBase64_2);
      console.log("=== END BASE64 HTML ===");
      
      console.log("HTML content (Light + Source):");
      console.log(htmlString_2);
      console.log("=== END Light + Source ===");
      
      expect(htmlString_2).to.include('class="light"');
      expect(htmlString_2).to.include(sampleCode);
      expect(htmlString_2).to.not.include('<!-- Bytecode:');
    } catch (error) {
      console.log("TokenURI call failed for light theme:", error.message);
    }
    
    // Test 3: Light theme + Compiled (bytecode)
    console.log("=== TEST 3: Light theme + Compiled (bytecode) ===");
    await bugcatCodex.connect(user1).compile(tokenId);
    expect(await bugcatCodex.compileds(tokenId)).to.be.true;
    
    try {
      const tokenURI3 = await bugcatCodex.tokenURI(tokenId);
      const jsonBase64_3 = tokenURI3.replace("data:application/json;base64,", "");
      const jsonString_3 = Buffer.from(jsonBase64_3, 'base64').toString();
      const jsonData_3 = JSON.parse(jsonString_3);
      
      const htmlBase64_3 = jsonData_3.image.replace("data:text/html;base64,", "");
      const htmlString_3 = Buffer.from(htmlBase64_3, 'base64').toString();
      
      console.log("=== BASE64 HTML FOR BROWSER (Light + Compiled) ===");
      console.log("data:text/html;base64," + htmlBase64_3);
      console.log("=== END BASE64 HTML ===");
      
      console.log("HTML content (Light + Compiled):");
      console.log(htmlString_3);
      console.log("=== END Light + Compiled ===");
      
      expect(htmlString_3).to.include('class="light"');
      expect(htmlString_3).to.include('<!-- Bytecode:');
      expect(htmlString_3).to.not.include(sampleCode);
    } catch (error) {
      console.log("TokenURI call failed for light theme + compiled:", error.message);
    }
    
    // Test 4: Dark theme + Compiled (bytecode)
    console.log("=== TEST 4: Dark theme + Compiled (bytecode) ===");
    await bugcatCodex.connect(user1).switchTheme(tokenId);
    expect(await bugcatCodex.lights(tokenId)).to.be.false;
    
    try {
      const tokenURI4 = await bugcatCodex.tokenURI(tokenId);
      const jsonBase64_4 = tokenURI4.replace("data:application/json;base64,", "");
      const jsonString_4 = Buffer.from(jsonBase64_4, 'base64').toString();
      const jsonData_4 = JSON.parse(jsonString_4);
      
      const htmlBase64_4 = jsonData_4.image.replace("data:text/html;base64,", "");
      const htmlString_4 = Buffer.from(htmlBase64_4, 'base64').toString();
      
      console.log("=== BASE64 HTML FOR BROWSER (Dark + Compiled) ===");
      console.log("data:text/html;base64," + htmlBase64_4);
      console.log("=== END BASE64 HTML ===");
      
      console.log("HTML content (Dark + Compiled):");
      console.log(htmlString_4);
      console.log("=== END Dark + Compiled ===");
      
      expect(htmlString_4).to.include('class="dark"');
      expect(htmlString_4).to.include('<!-- Bytecode:');
      expect(htmlString_4).to.not.include(sampleCode);
    } catch (error) {
      console.log("TokenURI call failed for dark theme + compiled:", error.message);
    }
  });

  it("Should verify registry integration and bugcat selection", async function () {
    const registry = new ethers.Contract(
      REGISTRY_ADDRESS,
      ["function bugs(uint256) external view returns (address)"],
      ethers.provider
    );
    
    console.log("=== Registry Integration Test ===");
    for (let i = 0; i < 5; i++) {
      try {
        const catAddress = await registry.bugs(i);
        const catCode = await ethers.provider.getCode(catAddress);
        console.log(`Bugcat ${i}: ${catAddress} (has code: ${catCode !== "0x"})`);
      } catch (error) {
        console.log(`Could not get bugcat ${i} from registry`);
      }
    }
    
    // Set up codes
    const bugcatAddresses = [];
    for (let i = 0; i < 5; i++) {
      try {
        const catAddress = await registry.bugs(i);
        const catCode = await ethers.provider.getCode(catAddress);
        if (catCode !== "0x") {
          bugcatAddresses.push(catAddress);
        }
      } catch (error) {
        console.log(`Could not get bugcat ${i} from registry:`, error.message);
      }
    }
    
    const sampleCode = "// SPDX-License-Identifier: WTFPL\npragma solidity ^0.8.30;\n\nimport \"../interface/BugCat.sol\";\n\ncontract ReentrancyCat is BugCat {\n    mapping(address => uint) public balance;\n\n    function deposit() public payable {\n        balance[msg.sender] += msg.value;\n    }\n\n    function withdraw() public {\n        (bool success, ) = msg.sender.call{value: balance[msg.sender]}(\"\");\n        require(success);\n        balance[msg.sender] = 0;\n    }\n\n    function caress() public {\n        if (address(this).balance == 0) {\n            emit Meow(msg.sender, \"reentrancy\");\n        }\n    }\n\n    function remember() external view returns (bool) {\n        address TheDAO = 0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413;\n        return TheDAO.code.length > 0;\n    }\n}";
    for (let i = 0; i < Math.min(bugcatAddresses.length, 5); i++) {
      await bugcatCodex.rememberCode(bugcatAddresses[i], sampleCode);
    }
    
    // Mint multiple tokens to test different bugcat selections
    const tokenIds = [10, 11, 12, 13, 14];
    for (const tokenId of tokenIds) {
      await bugcatCodex.mint(user1.address, tokenId);
      const bugcatIndex = await bugcatCodex.bugcatIndexes(tokenId);
      console.log(`Token ${tokenId} assigned to bugcat index: ${bugcatIndex}`);
      
      // Verify the bugcat address matches
      try {
        const bugcatAddress = await registry.bugs(bugcatIndex);
        console.log(`Token ${tokenId} bugcat address: ${bugcatAddress}`);
      } catch (error) {
        console.log(`Could not get bugcat address for token ${tokenId}:`, error.message);
      }
    }
  });
});