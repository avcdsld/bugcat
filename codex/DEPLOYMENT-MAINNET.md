# BUGCAT Codex - Mainnet Deployment Guide

## 前提条件

### 1. 環境変数の設定

`.env`ファイルに以下の変数を設定してください：

```bash
# Ethereum Mainnet RPC URL
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY

# Private key for deployment (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# Etherscan API Key for contract verification
ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

### 2. 必要なETHの準備

- デプロイメントには約0.01-0.02 ETHが必要です
- ガス価格が高い場合は追加のETHが必要になる可能性があります

### 3. BUGCATS Registry Addressの更新

**重要**: `scripts/deploy-mainnet.js`の`BUGCATS_REGISTRY_ADDRESS`を実際のメインネットアドレスに更新してください。

```javascript
const BUGCATS_REGISTRY_ADDRESS = "0x0000000000000000000000000000000000000000"; // TODO: Replace with actual mainnet address
```

## デプロイメント手順

### 1. コンパイル

```bash
npm run compile
```

### 2. メインネットにデプロイ

```bash
npm run deploy:mainnet
```

### 3. コントラクトの検証

```bash
npm run verify:mainnet
```

## デプロイメント後の確認

### 1. デプロイメント情報

デプロイメント完了後、`deployment-mainnet.json`ファイルが生成されます。このファイルには以下の情報が含まれます：

- デプロイされたコントラクトのアドレス
- コンストラクタ引数
- デプロイ時刻
- デプロイアカウント

### 2. Etherscanでの確認

- [Etherscan](https://etherscan.io)でデプロイされたコントラクトアドレスを確認
- コントラクトが正しく検証されていることを確認
- トランザクション履歴を確認

## トラブルシューティング

### よくある問題

1. **ガス不足エラー**
   - アカウントのETH残高を確認
   - ガス価格を調整

2. **ライブラリリンクエラー**
   - ENS Resolverライブラリのアドレスが正しいことを確認
   - メインネット: `0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e`

3. **検証エラー**
   - コンストラクタ引数が正しいことを確認
   - Etherscan APIキーが有効であることを確認

### 手動検証

自動検証が失敗した場合、以下のコマンドで手動検証できます：

```bash
# BugcatCodexRendererの検証
npx hardhat verify --network mainnet <CONTRACT_ADDRESS> <BUGCATS_REGISTRY_ADDRESS> "<SPECIAL_CODE_LIGHT>" "<SPECIAL_CODE_DARK>" --libraries contracts/utils/ENSResolver.sol:ENSResolver=0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e

# BugcatCodexの検証
npx hardhat verify --network mainnet <CONTRACT_ADDRESS> <OWNER_ADDRESS> <BUGCATS_REGISTRY_ADDRESS> <BUGCAT_COUNT> <RENDERER_ADDRESS> <ROYALTY_RECEIVER_ADDRESS>
```

## セキュリティ注意事項

1. **プライベートキーの管理**
   - `.env`ファイルをGitにコミットしないでください
   - 本番環境では安全なキー管理システムを使用してください

2. **デプロイ前の確認**
   - 全てのコンストラクタ引数が正しいことを確認
   - テストネットでの動作確認を推奨

3. **マルチシグの検討**
   - 本番環境ではマルチシグウォレットの使用を推奨

## サポート

問題が発生した場合は、以下を確認してください：

1. Hardhatのログ出力
2. Etherscanのトランザクション詳細
3. ガス価格とネットワークの状況

---

**注意**: メインネットへのデプロイは不可逆的な操作です。デプロイ前に十分にテストを行い、全ての設定を確認してください。
