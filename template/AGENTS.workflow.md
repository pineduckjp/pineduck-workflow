
## Development Workflow (Issue + PR)

All work follows `CONTRIBUTING.md`: plan in a GitHub Issue, implement on a branch, merge via PR. Follow these steps every time unless the user explicitly says otherwise.
Source and human-facing step table: https://github.com/pineduckjp/pineduck-workflow (tell the user which step you are on).

1. **Plan in an Issue first** (`feat` / `fix` only)
   - Before writing code, check for an existing Issue: `gh issue list`
   - If none exists, draft one from `.github/ISSUE_TEMPLATE/feat.md` or `fix.md` (fill in 実装方針 / 完了条件 / タスク), show it to the user, and create it after approval:
     `gh issue create --title "feat: ..." --label feat --milestone "<milestone>" --body-file <file>`
   - Other types (`docs`, `refactor`, `config`, ...) do not need an Issue.
2. **Branch from `develop`**
   - `git switch develop && git pull && git switch -c <type>/issue-<id>-<milestone>`
   - Without an Issue: `<type>/<short-description>`
   - Never commit directly to `main` or `develop`.
3. **Commit** using Conventional Commits, in Japanese, with the Issue reference in the body:
   ```text
   feat: 問い合わせ内容のメール通知を追加

   Issue #1
   ```
4. **Open a PR to `develop`** using `.github/pull_request_template.md`
   - Body contains `Issue #<id>` (not `Closes`), so the Issue stays open.
   - Run the project's test / typecheck / build before opening the PR.
   - `gh pr create --base develop --title "<type>: ..." --body-file <file>`
   - Check off completed tasks in the Issue: edit the body with `gh issue edit <id> --body-file <file>`.
5. **Release PR `develop` → `main`** only when the user asks. Body contains `Closes #<id>`.
6. Do not merge PRs, close Issues, or push to `main` without the user's explicit instruction.
