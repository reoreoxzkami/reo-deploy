# reo-deploy

GitHub に push するだけで、静的サイトも動的サイトも Cloudflare Workers に自動公開する、自作のデプロイサービスです。

## できること

- **静的サイト**: HTML / React / Vite / Astro など。ビルドして `dist`（なければ `public` かルート）を公開
- **動的サイト**: `server/index.js`（または `worker.js`）があれば、サーバー処理＋静的ファイルを1つのWorkerで公開
- **上級者向け**: リポジトリに `wrangler.toml` があれば、その設定のままデプロイ（D1・KV・R2なども使える）
- **PRプレビュー**: プルリクエストごとにプレビューURLを作成（β）
- `main` に push → 本番 `https://<名前>.<あなたのサブドメイン>.workers.dev`

## 初回だけの準備

1. Cloudflare で API トークンを作成（テンプレート「Edit Cloudflare Workers」）
2. 公開したいリポジトリの Settings → Secrets and variables → Actions に登録
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`

## サイトを公開する

`templates/deploy.yml` を、公開したいリポジトリの `.github/workflows/deploy.yml` にコピーして push するだけ。

## 判定ルール

| 条件 | モード |
|---|---|
| `wrangler.toml` / `wrangler.json(c)` がある | custom（その設定を使う） |
| `server/index.(js\|ts)` / `worker.(js\|ts)` / `_worker.js` がある | dynamic |
| それ以外 | static |

動的サイトでは `env.ASSETS.fetch(request)` で静的ファイルを返せます（`examples/dynamic-site` 参照）。

## 例

- `examples/static-site` … HTML だけのサイト
- `examples/dynamic-site` … `/api/hello` を返すサーバー付きサイト
