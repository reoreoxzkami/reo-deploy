#!/usr/bin/env bash
# reo-deploy: サイトの種類を判定し、Cloudflare Workers 用の設定を用意する
# 使い方: prepare.sh <worker名> <出力ディレクトリ>
set -euo pipefail

NAME="${1:?worker名が必要です}"
OUT_DIR="${2:-dist}"
TODAY="$(date -u +%Y-%m-%d)"

# Worker名は小文字英数字とハイフンのみ
NAME="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/^-+|-+$//g' | cut -c1-63)"

# 1) 自分で wrangler 設定を持っているなら、それを尊重する（動的サイト・上級者向け）
for f in wrangler.toml wrangler.json wrangler.jsonc; do
  if [ -f "$f" ]; then
    echo "mode=custom" >> "${GITHUB_OUTPUT:-/dev/null}"
    echo "config=$f" >> "${GITHUB_OUTPUT:-/dev/null}"
    echo "[reo-deploy] $f を検出: その設定でデプロイします"
    exit 0
  fi
done

# 2) サーバーのエントリがあれば動的サイト
ENTRY=""
for e in server/index.ts server/index.js worker.ts worker.js _worker.js; do
  if [ -f "$e" ]; then ENTRY="$e"; break; fi
done

# 静的ファイルの置き場所（出力ディレクトリが無ければ public、それも無ければ ルート）
ASSETS="$OUT_DIR"
if [ ! -d "$ASSETS" ]; then
  if [ -d public ]; then ASSETS="public"; elif [ -f index.html ]; then ASSETS="."; else ASSETS=""; fi
fi

if [ -n "$ENTRY" ]; then
  MODE="dynamic"
  if [ -n "$ASSETS" ]; then
    cat > .reo-wrangler.json <<JSON
{
  "name": "$NAME",
  "main": "$ENTRY",
  "compatibility_date": "$TODAY",
  "compatibility_flags": ["nodejs_compat"],
  "assets": { "directory": "$ASSETS", "binding": "ASSETS", "run_worker_first": false }
}
JSON
  else
    cat > .reo-wrangler.json <<JSON
{
  "name": "$NAME",
  "main": "$ENTRY",
  "compatibility_date": "$TODAY",
  "compatibility_flags": ["nodejs_compat"]
}
JSON
  fi
else
  MODE="static"
  if [ -z "$ASSETS" ]; then
    echo "[reo-deploy] エラー: 公開するファイルが見つかりません（$OUT_DIR / public / index.html）" >&2
    exit 1
  fi
  cat > .reo-wrangler.json <<JSON
{
  "name": "$NAME",
  "compatibility_date": "$TODAY",
  "assets": { "directory": "$ASSETS", "not_found_handling": "single-page-application" }
}
JSON
fi

# ルートを丸ごと公開する場合は、リポジトリの裏側を出さない
if [ "$ASSETS" = "." ]; then
  printf '.git\n.reo-deploy\n.github\n.wrangler\n.assetsignore\nnode_modules\n.reo-wrangler.json\n*.md\n' > .assetsignore
fi

echo "mode=$MODE" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "config=.reo-wrangler.json" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "[reo-deploy] モード: $MODE / 公開フォルダ: ${ASSETS:-なし} / エントリ: ${ENTRY:-なし}"
cat .reo-wrangler.json
