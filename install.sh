#!/usr/bin/env bash
# Issue + PR ワークフローのテンプレートを対象プロジェクトへ導入する
#
# 使い方: ./install.sh <target-dir> [--force] [--labels]
#   --force   既存のテンプレートファイルを上書きする
#   --labels  gh CLI で type ラベル (feat / fix / docs ...) を対象リポジトリに作成する
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "$0")/template" && pwd)"
MARKER="## Development Workflow (Issue + PR)"

target=""
force=false
labels=false
for arg in "$@"; do
  case "$arg" in
    --force) force=true ;;
    --labels) labels=true ;;
    -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) target="$arg" ;;
  esac
done

if [[ -z "$target" || ! -d "$target" ]]; then
  echo "error: 対象ディレクトリを指定してください" >&2
  exit 1
fi
target="$(cd "$target" && pwd)"

copy_file() {
  local rel="$1"
  local dest="$target/$rel"
  if [[ -e "$dest" && "$force" != true ]]; then
    echo "skip     $rel (既に存在します。上書きは --force)"
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  cp -p "$TEMPLATE_DIR/$rel" "$dest"
  echo "copy     $rel"
}

copy_file .github/ISSUE_TEMPLATE/feat.md || true
copy_file .github/ISSUE_TEMPLATE/fix.md || true
copy_file .github/ISSUE_TEMPLATE/config.yml || true
copy_file .github/pull_request_template.md || true
copy_file CONTRIBUTING.md || true

# シークレットファイル保護 (Claude Code の権限設定とフック)
copy_file .claude/hooks/protect-secrets.py || true
if ! copy_file .claude/settings.json; then
  echo "         → .claude/settings.json の permissions.deny と hooks.PreToolUse を手動でマージしてください"
  echo "           (参照: $TEMPLATE_DIR/.claude/settings.json)"
fi

# AI エージェント向けのワークフロー規約を AGENTS.md / CLAUDE.md に追記する
append_agents() {
  local rel="$1"
  local dest="$target/$rel"
  if [[ -f "$dest" ]] && grep -qF "$MARKER" "$dest"; then
    echo "skip     $rel (ワークフロー規約は追記済みです)"
    return
  fi
  cat "$TEMPLATE_DIR/AGENTS.workflow.md" >> "$dest"
  echo "append   $rel"
}

agent_files=0
for f in AGENTS.md CLAUDE.md; do
  if [[ -f "$target/$f" ]]; then
    append_agents "$f"
    agent_files=$((agent_files + 1))
  fi
done
if [[ "$agent_files" -eq 0 ]]; then
  append_agents AGENTS.md
fi

if [[ "$labels" == true ]]; then
  (
    cd "$target"
    gh label create feat --color a2eeef --description "機能追加" --force
    gh label create fix --color d73a4a --description "バグ修正" --force
    gh label create docs --color 0075ca --description "ドキュメント" --force
    gh label create style --color f9d0c4 --description "見た目・フォーマット" --force
    gh label create refactor --color d4c5f9 --description "リファクタリング" --force
    gh label create config --color c5def5 --description "設定ファイル" --force
    gh label create test --color bfd4f2 --description "テスト" --force
    gh label create ci --color 0e8a16 --description "CI/CD" --force
  )
  echo "label    feat, fix, docs, style, refactor, config, test, ci"
fi

echo
echo "完了: $target"
echo "次の手順は README.md の「導入後の設定」を参照してください。"
