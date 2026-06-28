require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.30",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  // Etherscan API V2: one key works across all chains (set ETHERSCAN_API_KEY in .env).
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || ""
  },
  networks: {
    // Fork mainnet only when MAINNET_RPC_URL is set, so `npx hardhat test` runs on a fresh
    // in-memory chain by default (the cat caress/Meow flows need no fork).
    hardhat: process.env.MAINNET_RPC_URL ? {
      forking: {
        url: process.env.MAINNET_RPC_URL,
        blockNumber: 23041000
      }
    } : {},
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "https://eth-mainnet.g.alchemy.com/v2/PROJECT_ID",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "https://eth-sepolia.g.alchemy.com/v2/PROJECT_ID",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  }
};
