#!/usr/bin/env bash
# Claude Code の PreToolUse フック (Bash)。シークレットの混入につながる git 操作を止める。
#   - git add -A / --all / . / -u / *  (ファイルを指定して追加すること)
#   - git commit -a / --all
#   - --no-verify (フックの回避)
#   - git commit / git push の前に、シークレットの混入チェックを実行
cmd=$(python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("command",""))' 2>/dev/null)
block() { echo "Blocked: $1" >&2; exit 2; }

git_re='(^|[;&|(]|[[:space:]])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]-][^[:space:]]*)?)*[[:space:]]+'

if echo "$cmd" | grep -Eq "${git_re}add([[:space:]]+-[^[:space:]]+)*[[:space:]]+(-A|--all|-u|--update|\.|\*)([[:space:]]|$|[;&|])"; then
  block "git add -A / git add . / git add -u は使いません。追加するファイルを一つずつ指定し、git status と git diff --cached --name-only で中身を確認してください。"
fi
if echo "$cmd" | grep -Eq "${git_re}commit[^;&|]*[[:space:]](-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)"; then
  block "git commit -a は使いません。追加するファイルを指定してください。"
fi
if echo "$cmd" | grep -Eq "${git_re}(commit|push)[^;&|]*--no-verify"; then
  block "--no-verify でシークレット検査を回避しないでください。"
fi

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
if [ -x "$root/.githooks/check-secrets.sh" ]; then
  if echo "$cmd" | grep -Eq "${git_re}commit([[:space:]]|$)"; then
    "$root/.githooks/check-secrets.sh" staged || exit 2
  fi
  if echo "$cmd" | grep -Eq "${git_re}push([[:space:]]|$)"; then
    "$root/.githooks/check-secrets.sh" outgoing || exit 2
  fi
fi
exit 0
