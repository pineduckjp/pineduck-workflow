#!/usr/bin/env bash
# シークレットの混入チェック (commit / push の前に実行する)
#
# 使い方:
#   check-secrets.sh staged     ... ステージ済みの変更を調べる (pre-commit)
#   check-secrets.sh push       ... 標準入力の push 対象 (pre-push フックの形式) を調べる
#   check-secrets.sh outgoing   ... 現在のブランチの未 push のコミットを調べる
#
# 調べること:
#   1. シークレットらしいファイル名 (環境変数ファイル、秘密鍵など。*.example は除く)
#   2. 追加された行にある、API キーなどの形をした文字列
#   3. ローカルのシークレットファイルが、.gitignore で無視されているか
# push では、途中のコミットで追加して後で消したファイルも検出する (履歴に残るため)。
set -uo pipefail

mode="${1:-staged}"
zero="0000000000000000000000000000000000000000"
problems=()

name_re='(^|/)(\.wrangler/.*|\.env(\.[^/]*)?|\.dev\.vars(\.[^/]*)?|id_rsa|id_ed25519|id_ecdsa|credentials\.json|service-account[^/]*\.json|[^/]*\.(pem|key|p12|pfx|keystore))$'
safe_re='\.(example|sample|template|dist)$'
sq="'"
content_re="(re_[A-Za-z0-9]{20,}|sb_secret_[A-Za-z0-9_-]{16,}|sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{32,}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(api[_-]?key|secret|token|password|passwd)[A-Za-z0-9_]*[[:space:]]*[:=][[:space:]]*[\"${sq}][A-Za-z0-9/+_.-]{24,}[\"${sq}]|^\+?[A-Z][A-Z0-9_]*(KEY|SECRET|TOKEN|PASSWORD)[A-Z0-9_]*=[^[:space:]\"${sq}]{24,})"
excludes=(-- . ':(exclude)*.example' ':(exclude)*.sample' ':(exclude)*.template')

# 検査するコミットの範囲を、git log に渡す引数として作る
ranges=()
case "$mode" in
  staged) ;;
  push)
    while read -r _lref lsha _rref rsha; do
      [ -z "${lsha:-}" ] && continue
      [ "$lsha" = "$zero" ] && continue   # ブランチの削除
      if [ "$rsha" = "$zero" ]; then
        ranges+=("$lsha --not --remotes")
      else
        ranges+=("$rsha..$lsha")
      fi
    done
    ;;
  outgoing)
    if git rev-parse --verify -q '@{u}' >/dev/null; then ranges+=("@{u}..HEAD"); else ranges+=("HEAD --not --remotes"); fi
    ;;
  *) echo "usage: $0 staged|push|outgoing" >&2; exit 2 ;;
esac

files=""
added=""
if [ "$mode" = "staged" ]; then
  files=$(git diff --cached --name-only --diff-filter=ACMR)
  added=$(git diff --cached -U0 --no-color --diff-filter=ACMR "${excludes[@]}" | grep -E '^\+[^+]' || true)
else
  for r in "${ranges[@]:-}"; do
    [ -z "$r" ] && continue
    # shellcheck disable=SC2086
    files+=$'\n'$(git log $r --name-only --pretty=format: --diff-filter=ACMR 2>/dev/null)
    # shellcheck disable=SC2086
    added+=$'\n'$(git log $r -p -U0 --no-color --pretty=format: --diff-filter=ACMR "${excludes[@]}" 2>/dev/null | grep -E '^\+[^+]' || true)
  done
fi

# 1. ファイル名
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if [[ "$f" =~ $name_re ]] && ! [[ "$f" =~ $safe_re ]]; then
    problems+=("シークレットらしいファイル名: $f")
  fi
done < <(printf '%s\n' "$files" | sort -u)

# 2. 追加された行の中身 (値そのものは表示しない)
hits=$(printf '%s\n' "$added" | grep -Ec "$content_re" || true)
if [ "${hits:-0}" -gt 0 ]; then
  problems+=("API キーなどの形をした文字列が ${hits} 行に含まれています (値は表示しません。git diff で確認してください)")
fi

# 3. ローカルのシークレットファイルが無視されているか
root=$(git rev-parse --show-toplevel)
for f in "$root"/.env "$root"/.env.* "$root"/.dev.vars "$root"/.dev.vars.*; do
  [ -e "$f" ] || continue
  b=$(basename "$f")
  [[ "$b" =~ $safe_re ]] && continue
  if ! git check-ignore -q "$f"; then
    problems+=("$b が .gitignore で無視されていません (Git に入るおそれがあります)")
  fi
done

if [ "${#problems[@]}" -gt 0 ]; then
  echo "✖ シークレットの混入を検出しました。中止します。" >&2
  for p in "${problems[@]}"; do echo "  - $p" >&2; done
  echo "  対処: 該当のファイルをコミットに含めない / .gitignore に追加する。すでにコミットした場合は、キーを再発行してから、履歴の扱いを相談してください。" >&2
  exit 1
fi
exit 0
