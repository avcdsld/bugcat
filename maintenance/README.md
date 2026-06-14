# BUGCAT 展示ページ メンテナンスメモ

展示ページ本体は `website/exhibition/index.html`。Cloudflare Pages で `website/` 全体を
デプロイし、本ページは **`/exhibition/`** で配信される。

> **重要**: `wrangler pages deploy` は `.assetsignore` を尊重しない（`node_modules` だけは
> Pages のデフォルトで除外されるが、それ以外は `website/` 配下を**すべて公開**する）。
> そのため、このメモとフォントツールは公開ディレクトリの外＝**リポジトリ直下 `maintenance/`**
> に置いてある（＝デプロイされない唯一確実な方法）。`website/` 配下に置くと公開される。

## 構成

| パス | 役割 |
|------|------|
| `website/exhibition/index.html` | 本体。CSS・JS・フォント(base64 woff2)をすべて1ファイルに内包 |
| `website/exhibition/three.min.js` | 背景の墨流し（WebGL流体）に使う Three.js |
| `maintenance/regen-fonts.py` | フォントサブセット再生成スクリプト（下記）。**website/ の外＝非デプロイ** |
| `maintenance/*.ttf` | 源フォントのキャッシュ（自動DL）。**非デプロイ** |
| `website/functions/api/*.js` | バックエンド API（Cloudflare Pages Functions） |
| `website/wrangler.toml` | Pages 設定・環境変数・D1 バインディング（注: 現状これ自体も公開されている） |
| `website/schema.sql` | 匿名インタラクションログ（D1）のスキーマ |

## index.html のしくみ

- タブ＝ネコ。各ネコに対し `remember()` / `caress()` / `help` を実行できる。
  - `remember()` … 由来となった歴史的コントラクトが今も Ethereum 上に在るかをチェーン読取で確認。
  - `caress()` … 脆弱性を突く攻撃 tx を送信し、条件成立で `Meow` イベント＝ネコが鳴く。
- ネコの定義・ソース・ポエムは `CATS` 配列、UI 文言は `T`（`ja`/`en`）に集約。
- 操作演出のタイミング定数（`/* ASYNC OPS */` 付近）:
  - `MIN_DUR` … API 応答を「準備完了」とみなすまでの最低時間（remember 3s / caress 6s）。
  - `MIN_QUERY` … 「続ける」を押してから結果が出るまで、確認表示を必ず見せる最低時間
    （**remember 5s / caress 10s**）。表示ラベルは `T.*.qryR`（確認中）/ `qryC`（トランザクション送信中）。
  - 仕組み: 「続ける」で `querying` 状態に入り、`finishQuery()` が「結果が揃った」かつ
    「`MIN_QUERY` 経過」の両方を満たすまで待ってから結果ビートを表示する。

## バックエンド / 環境変数

- `wrangler.toml` の `DRY_RUN="true"` の間は **署名・ブロードキャストしない**。
  `remember` は対象を「存在する」と返し、`caress` は擬似 `Meow` を返す（安全なデモ動作）。
  ドライラン時は `caress` レスポンスに `dryRun:true` が付き、コンソールに「ドライラン中…」を1行表示する。
- **展示期間ゲート（`functions/api/_shared.js` の `caressDryRun`）**: `caress()` の実トランザクションは
  **展示期間中のみ**送信し、期間外は必ずドライランになる（フェイルセーフ）。期間は JST 固定で
  `EXHIBITION_START`/`EXHIBITION_END` 定数（現在 **2026-07-15 00:00 〜 2026-07-21 00:00 JST**＝7/15〜7/20）。
  期間を変えるときはこの2定数を編集する。`remember`（読取のみ）は対象外。
- **本番（実チェーン）にする手順**:
  1. シークレットを設定: `RPC_URL`（mainnet RPC）, `PRIVATE_KEY`（ガス支払い用、
     `wrangler pages secret put PRIVATE_KEY`）, `SEEKER_ADDR` / `PROPHET_ADDR`（caress 補助コントラクト）, 任意 `SEEKER_VALUE`。
  2. `DRY_RUN` を `"false"`（または未設定）にする。`"true"` の間は期間内でも強制ドライラン（手動オーバーライド）。
  - 送信は「`DRY_RUN` が false」かつ「`PRIVATE_KEY` あり」かつ「展示期間内」の3条件が揃ったときのみ。
    期間が過ぎれば `DRY_RUN="false"` のままでも自動でドライランに戻る。
- ローカルは `.dev.vars`（`.dev.vars.example` をコピー、gitignore 済み）。
  ドライラン表示の確認は `npx wrangler pages dev .`（静的サーバだと `/api/*` が無く `dryRun` が付かない）。

## フォントの再生成（重要）

`index.html` には 4 つのフォントを base64 woff2 で埋め込んでいる（先頭の `@font-face`）:

| フォント | 用途 | サブセット内容 |
|----------|------|----------------|
| Cormorant Garamond | ロゴ・タブ（Latin 表示） | ASCII のみ |
| JetBrains Mono | ターミナル/ソースの Latin（等幅） | ASCII＋一部記号 |
| **Shippori Mincho**（明朝） | 概要・あとがきの**本文**、および serif スタックの fallback | **使用する全非ASCII文字** |
| **M PLUS 1 Code**（ゴシック） | **コンソール**（出力・選択肢・help・入力欄）の日本語 | **使用する全非ASCII文字** |

日本語は用途で2フォントに分かれる:
- 等幅スタック `'JetBrains Mono','M PLUS 1 Code',monospace`（body・各 `pre`・`.fb-text`・
  `.view-pre`）→ コンソールの日本語は **M PLUS 1 Code**（JetBrains Mono と馴染むゴシック）。
- serif スタック `'Shippori Mincho',serif`（`.overview`）と `.tab-after` → 本文は **明朝**。

両フォントとも**ページで使う非ASCII文字をすべて含む必要がある**（含まれない字は OS
フォントにフォールバック＝開発 Mac では見えるが日本語フォントの無い展示端末では崩れる）。
日本語テキストを追加・変更したら再生成する:

```sh
cd maintenance
python3 regen-fonts.py --check   # 各フォントの不足文字を確認（書き換えない）
python3 regen-fonts.py           # 両サブセットを再生成して website/exhibition/index.html を更新
```

- スクリプトは index.html 内の非ASCII文字を集計し、`FONTS` に列挙した各源フォントを
  サブセット → 該当 `@font-face` の base64 を差し替える（無ければ新規追加）。
  対象は `HTML = HERE.parent/"website"/"exhibition"/"index.html"`（スクリプトは `maintenance/`）。
- 源フォントは初回に `maintenance/` へ自動DLしてキャッシュ。M PLUS 1 Code は
  可変フォントなので weight 400 にインスタンス化してからサブセットする。URL が切れたら
  手動で同フォルダに `.ttf` を置けばよい。
- フォントを増減/差し替えるときは `maintenance/regen-fonts.py` の `FONTS` を編集する。
- 必要ツール: `pip3 install --user fonttools brotli`（`pyftsubset` を PATH に）。
- Cormorant / JetBrains Mono は ASCII のみで変化しないため触らない。

### 既知の小欠落（OS フォント表示。実害ほぼ無し）
- `⤢`（U+2922, ソース展開ボタンのアイコン）はどの源フォントにも無い。気になるなら別グリフに。
- `→`（U+2192）は M PLUS 1 Code 源に無く、コンソールの `→ true` 等はシステム等幅で表示
  （字形は普遍的なので問題なし）。本文側（明朝）の `→` は Shippori Mincho で表示。
- `─`（U+2500）は HTML コメント内のみで非表示。

## デプロイ

Cloudflare Pages（プロジェクト名 `bugcat`、出力ディレクトリ `.` = `website/`）。

```sh
cd website
npx wrangler pages dev .        # ローカル（.dev.vars を読む）
npx wrangler pages deploy .     # 本番デプロイ
```

- **公開範囲の注意（重要）**: `wrangler pages deploy` は `.assetsignore` を尊重しない。`website/` 配下に
  置いたものは（`node_modules`・`functions/` ソースを除き）**ドットファイルも含めすべて公開される**。
  - 非公開にしたいファイルは `website/` の外（`maintenance/` 等）に置く（＝確実）。README・フォント
    ツール・源フォントはこのためここに置いている。
  - `website/` 内に残さざるを得ない設定ファイル（`wrangler.toml`/`package.json`/`package-lock.json`/
    `schema.sql`/`.dev.vars*`/`.assetsignore`）は **`website/_redirects` で 301 ブロック済み**。
    設定ファイルを増やしたら `_redirects` にも追記すること。
  - とくに **`.dev.vars`（ローカル用の実シークレット）を作った場合**、`_redirects` で塞いでいても
    アップロード自体はされる。確実を期すなら deploy 前に存在しないことを確認する。
- 既定は `DRY_RUN="true"`。実チェーン送信は上記シークレット設定後に切り替える。
