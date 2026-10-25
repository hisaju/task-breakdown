#!/usr/bin/env bash
# 編集された Ruby ファイルに RuboCop の安全な自動修正をかける（PostToolUse フック）
set -euo pipefail

file=$(jq -r '.tool_input.file_path // empty')
[[ "$file" == *.rb ]] || exit 0
[[ -f "$file" ]] || exit 0

cd "$CLAUDE_PROJECT_DIR"
rel="${file#"$CLAUDE_PROJECT_DIR"/}"

# web コンテナが起動していれば exec、無ければスキップ（フックで起動まではしない）
if docker compose ps --status running --services 2>/dev/null | grep -qx web; then
  docker compose exec -T web bin/rubocop -a --format quiet "$rel" >/dev/null 2>&1 || true
fi
exit 0
