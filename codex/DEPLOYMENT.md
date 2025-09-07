# BugcatCodex Deployment Guide

## Holesky Testnet Deployment

### Prerequisites

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment variables:**
   Create a `.env` file in the root directory with:
   ```
   PRIVATE_KEY=your_private_key_here
   HOLESKY_RPC_URL=https://ethereum-holesky.publicnode.com
   ```

3. **Get Holesky ETH:**
   - Visit [Holesky Faucet](https://faucets.chain.link/holesky-testnet)
   - Or use [Alchemy Faucet](https://sepoliafaucet.com/)

### Deployment Steps

1. **Compile contracts:**
   ```bash
   npm run compile
   ```

2. **Deploy to Holesky:**
   ```bash
   npm run deploy:holesky
   ```

### Important Notes

⚠️ **Before deployment, you need to update the BugcatsRegistry address:**

1. Open `scripts/deploy-holesky.js`
2. Find the line: `const BUGCATS_REGISTRY_ADDRESS = "0x0000000000000000000000000000000000000000";`
3. Replace with the actual BugcatsRegistry contract address on Holesky

### Deployment Output

The script will:
- Deploy BugcatCodexRenderer
- Deploy BugcatCodex
- Set the renderer in BugcatCodex
- Save deployment info to `deployment-holesky.json`

### Verification

After deployment, you can verify the contracts on Holesky Etherscan:

**Automatic verification:**
```bash
npm run verify:holesky
```

**Manual verification:**
```bash
# BugcatCodexRenderer
npx hardhat verify --network holesky <RENDERER_ADDRESS> "0x7ECAbf2b07151EFE130706bA1580d29CF7bFF45B" --libraries "ENSResolver:0x6925affDa98274FE0376250187CCC4aC62866dCd"

# BugcatCodex
npx hardhat verify --network holesky <CODEX_ADDRESS> <OWNER_ADDRESS> "0x7ECAbf2b07151EFE130706bA1580d29CF7bFF45B" 5 <RENDERER_ADDRESS> <ROYALTY_RECEIVER_ADDRESS>
```

### Troubleshooting

- **Insufficient funds:** Make sure you have enough Holesky ETH
- **Network issues:** Check your RPC URL
- **Registry address:** Ensure the BugcatsRegistry address is correct
