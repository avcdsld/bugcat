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

メインネットには **5 匹のネコは既にデプロイ済み**（`_shared.js` の `CAT_ADDRS`）。cat 契約は今回の
Sepolia 作業で変更していない（変えたのは `Seeker.sol` の返金フィックスのみ）ので、**ネコは再デプロイせず、
補助コントラクト 2 つ（Seeker / Prophet）だけ**を既存ネコに対してデプロイすればよい。

- cat 0 ReentrancyCat … `Seeker` が必要（コンストラクタで既存 ReentrancyCat に束縛）
- cat 1 PredictableCat … `Prophet` が必要（`caress(address)` で cat 非依存、1 つで足りる）
- cat 2/3/4 … website が直接 exploit するので補助コントラクト不要

### 6-1. 補助 2 つをデプロイ

`v8/.env` に `MAINNET_RPC_URL` と資金入り `PRIVATE_KEY`（＝caress 送信者）を設定し:

```bash
cd v8 && npx hardhat run scripts/deploy-mainnet-helpers.js --network mainnet
```

- 既存 mainnet ReentrancyCat（`CAT_ADDRS[0]`）に対して `Seeker` を、汎用の `Prophet` をデプロイする。
- `deployment-mainnet.json` に保存し、`SEEKER_ADDR` / `PROPHET_ADDR` をコンソール表示する。
- ネコを別アドレスへ移した場合のみ `REENTRANCY_CAT_ADDR` 環境変数で上書き可能。
- 再実行時に既デプロイ分をスキップしたい場合は `SEEKER_ADDR=0x.. PROPHET_ADDR=0x..` を渡す（その分はデプロイせず再利用）。
- （任意）出力の `npx hardhat verify ...` で Etherscan 検証。

> **RPC は標準準拠のものを使うこと（Alchemy / Infura 推奨）。** contract-creation の応答で `to` を
> `""`（空文字）で返す非準拠 RPC だと、ethers v6 が `invalid address value=""` で落ちる
> （Tx 自体はブロードキャスト済みになる点に注意）。落ちた場合は Etherscan で送信済み Tx を確認し、
> 既にできた helper があれば上の `SEEKER_ADDR` / `PROPHET_ADDR` で再開する。

### 6-2. Cloudflare Pages の設定

```bash
cd website
npx wrangler pages secret put RPC_URL        # mainnet RPC URL
npx wrangler pages secret put PRIVATE_KEY    # 資金入り送信者の秘密鍵
# 変数（wrangler.toml の [vars] かダッシュボード）:
#   CHAIN     = "mainnet"   （または未設定。sepolia 以外は mainnet 扱い）
#   DRY_RUN   = "false"
#   SEEKER_ADDR  = <6-1 の Seeker>
#   PROPHET_ADDR = <6-1 の Prophet>
```

`CAT_ADDRS` は既存のままでよい（差し替え不要）。

### 6-3. 展示期間ゲート

メインネットは展示期間ゲートが効くので、`DRY_RUN="false"` でも **2026-07-15〜20 (JST) の期間内のみ**
実送信される（期間外は自動で dry-run）。期間外に 1 匹だけ本番疎通を試すなら、`v8/scripts/feed.js` を
`--network mainnet` で実行できる（**実 ETH を消費し、Meow が本番で発火する**点に注意）。

---

## 補足: PredictableCat は 1 回勝負

`Prophet.caress()` は 10 回の flip が同一ブロックハッシュに依存するため、結果は **all-or-nothing（約 1/2）**。
API は **リトライせず 1 回だけ**送る。外れたときは tx は成功するが Meow は出ず、exhibition では
「10回の連勝は揃わず、ネコは鳴きませんでした。運が悪かった」と正直に表示される（これは仕様）。
tx 自体が失敗した場合は `tx failed.` を表示する（成功を偽装しない）。

## 補足: Seeker を変更したら（自動返金フィックス等）

`Seeker.sol` は caress の最後にドレインした ETH を呼び出し者へ全額返金するので、Seeker に ETH が
溜まらない。`Seeker.sol` を変更したら **Seeker のみ再デプロイ**し、`SEEKER_ADDR` を更新する:

```bash
cd v8 && npx hardhat run scripts/redeploy-seeker.js --network sepolia
# 出力の SEEKER_ADDR を Cloudflare Pages の環境変数に反映
```

（猫・Prophet は不変なので `CAT_ADDRS_SEPOLIA` の更新は不要。）

## 補足: ReentrancyCat の入金額

`SEEKER_VALUE`（wei、既定 1）が再入の 1 回あたり送金額。既定の 1 wei なら ReentrancyCat に
追加入金しなくても残高が 0 になり Meow する。事前入金する場合は **必ず `SEEKER_VALUE` の倍数**にすること
（端数が残ると `withdraw` の送金が失敗して revert する）。
