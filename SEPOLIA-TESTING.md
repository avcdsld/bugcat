# Sepolia テスト → メインネット稼働 手順書

`website` の `DRY_RUN="false"`（実トランザクション送信）を、まず **Sepolia テストネット**で確認し、
最終的に **Ethereum メインネット**で動かすための手順。

> チェーンに繋ぐ処理（コンパイル・デプロイ・feed 送信・wrangler secret 設定）は **あなたのローカル環境**で
> 実行してください。Claude の実行環境は外向きの RPC / solc 配布へアクセスできません。

---

## 0. 前提・用意するもの

| 必要なもの | 用途 |
|---|---|
| Sepolia RPC URL（Alchemy 等） | デプロイ・読み書き |
| 使い捨ての秘密鍵 1 本 | デプロイ署名 ＝ website の caress 送信者を兼ねる |
| SepETH（上の鍵のアドレスへ） | ガス代。0.2〜0.5 SepETH もあれば十分 |
| Etherscan API Key（任意） | コントラクト検証（verify）に使用。1 本で mainnet/sepolia 兼用 |

ネコは Solidity のバージョン差で 2 プロジェクトに分かれている。**両方デプロイが必要**。

| index | ネコ | プロジェクト | caress 経路 |
|---|---|---|---|
| 0 | ReentrancyCat | `v8` | Seeker 経由の再入 |
| 1 | PredictableCat | `v8` | Prophet 経由の予測 |
| 2 | OverflowCat | `v4` | batchTransfer オーバーフロー → caress |
| 3 | UnprotectedCat | `v4` | init で所有権奪取 → caress |
| 4 | MisspelledCat | `v4` | 綴り間違い constructor で所有権奪取 → caress |

---

## 1. 依存インストール & ローカル検証（送金なし）

`v8`・`v4` それぞれで実行。hardhat 内蔵 EVM で Meow が出ることを先に確認する（SepETH 不要）。

```bash
cd v8 && npm install && npx hardhat test
cd ../v4 && npm install && npx hardhat test
```

`v8` のテストは ReentrancyCat / PredictableCat の Meow を検証する。
`v4` も同様にコンパイル＋テストが通ればOK。

---

## 2. .env を用意（v8・v4 共通の内容）

各プロジェクト直下に `.env`（gitignore 済み）を作成:

```bash
# v8/.env と v4/.env の両方に同じ内容で置く
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/<YOUR_KEY>
PRIVATE_KEY=<0xなしの秘密鍵>
ETHERSCAN_API_KEY=<任意>
```

`PRIVATE_KEY` のアドレスに SepETH を送っておくこと。

---

## 3. Sepolia へデプロイ

```bash
# v8（ReentrancyCat / Seeker / PredictableCat / Prophet）
cd v8 && npx hardhat run scripts/deploy-sepolia.js --network sepolia

# v4（OverflowCat / UnprotectedCat / MisspelledCat）
cd ../v4 && npx hardhat run scripts/deploy-sepolia.js --network sepolia
```

それぞれ `deployment-sepolia.json` にアドレスが保存され、コンソールに
`CAT_ADDRS_SEPOLIA` / `SEEKER_ADDR` / `PROPHET_ADDR` 用の値が表示される。

（任意）Etherscan 検証はコンソール出力の `npx hardhat verify ...` をそのまま実行。

---

## 4. オンチェーンで Meow を発火（feed）

デプロイした各ネコに、website と同じ攻撃手順で caress し、Meow イベントを assert する。

```bash
cd v8 && npx hardhat run scripts/feed.js --network sepolia
cd ../v4 && npx hardhat run scripts/feed.js --network sepolia
```

全ネコで `Meow=true` になれば、チェーン側の準備は完了。
（PredictableCat は確率ゲートのため最大 8 回リトライする。）

---

## 5. website を Sepolia 向けに設定して確認

### 5-1. ネコのアドレスを反映

`website/functions/api/_shared.js` の `CAT_ADDRS_SEPOLIA` に、手順 3 の 5 アドレスを順番通り記入してコミットする。
（コミットしたくない場合は、代わりに wrangler の環境変数 `CAT_ADDR_0`..`CAT_ADDR_4` で上書きも可能。）

### 5-2. Cloudflare Pages の変数・シークレット

```bash
cd website
# 変数（平文）
npx wrangler pages secret put RPC_URL        # Sepolia RPC URL を入力
npx wrangler pages secret put PRIVATE_KEY    # caress 送信者の秘密鍵（SepETH 必要）
# 以下は wrangler.toml の [vars] でも、ダッシュボードの環境変数でも可
#   CHAIN     = "sepolia"
#   DRY_RUN   = "false"
#   SEEKER_ADDR  = <Seeker アドレス>
#   PROPHET_ADDR = <Prophet アドレス>
```

ポイント:
- `CHAIN="sepolia"` の時だけ展示期間ゲートが外れ、`DRY_RUN="false"` で常時実トランザクションを送る。
- メインネット（`CHAIN="mainnet"`）は従来通り **展示期間 2026-07-15〜20 (JST) 内のみ**実送信。
- Sepolia では `remember()` は歴史的コントラクトが無いため `false`（仕様通り。今回の確認対象は caress/Meow）。

### 5-3. ローカルプレビュー（任意）

`website/.dev.vars` に同じ変数を置けば `npx wrangler pages dev` でローカル確認できる。

### 5-4. 動作確認

exhibition ページ（`/exhibition/?debug=true` でゲート解放）で各ネコを caress → Meow 表示と
`tx ...↗`（sepolia.etherscan.io へのリンク）が出れば成功。

---

## 6. メインネット移行

1. `v8` / `v4` を `--network mainnet`（`MAINNET_RPC_URL` を `.env` に設定）でデプロイ。
2. デプロイした 5 アドレスを `website/functions/api/_shared.js` の `CAT_ADDRS`（mainnet 用）に反映。
   （※ 既存の `CAT_ADDRS` は現行デプロイ済みアドレス。新規デプロイするなら差し替え。）
3. wrangler を `CHAIN="mainnet"`、`DRY_RUN="false"`、`RPC_URL`=mainnet、`SEEKER_ADDR`/`PROPHET_ADDR`=mainnet版、
   `PRIVATE_KEY`=資金入り送信者 に設定。
4. メインネットは展示期間ゲートが効くので、**期間内のみ**実送信される。

---

## 補足: ReentrancyCat の入金額

`SEEKER_VALUE`（wei、既定 1）が再入の 1 回あたり送金額。既定の 1 wei なら ReentrancyCat に
追加入金しなくても残高が 0 になり Meow する。事前入金する場合は **必ず `SEEKER_VALUE` の倍数**にすること
（端数が残ると `withdraw` の送金が失敗して revert する）。
