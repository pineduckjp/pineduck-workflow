
## Development Workflow (Issue + PR)

All work follows `CONTRIBUTING.md`: plan in a GitHub Issue, implement on a branch, merge via PR. Follow these steps every time unless the user explicitly says otherwise.
Source and human-facing step table: https://github.com/pineduckjp/pineduck-workflow (tell the user which step you are on).

1. **Plan in an Issue first** (`feat` / `fix` only)
   - Before writing code, check for an existing Issue: `gh issue list`
   - If none exists, draft one from `.github/ISSUE_TEMPLATE/feat.md` or `fix.md` (fill in 実装方針 / 完了条件 / タスク), show it to the user, and create it after approval:
     `gh issue create --title "feat: ..." --label feat --milestone "<milestone>" --assignee @me --body-file <file>`
   - Create the milestone first if it does not exist: `gh api repos/{owner}/{repo}/milestones -f title="<milestone>"`
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
   - `gh pr create --base develop --title "<type>: ..." --label <type> --milestone "<milestone>" --assignee @me --body-file <file>`
   - Always set **assignee (`@me`), label (= `<type>`), and milestone** (same as the Issue; omit `--milestone` only when there is no Issue) on both Issues and PRs. Verify with `gh pr view <n> --json assignees,labels,milestone`.
   - Check off completed tasks in the Issue: edit the body with `gh issue edit <id> --body-file <file>`.
5. **Release PR `develop` → `main`** only when the user asks. Body contains `Closes #<id>`. Set assignee / label / milestone the same way.
6. Do not merge PRs, close Issues, or push to `main` without the user's explicit instruction.
7. **Never touch secret files** (`.dev.vars`, `.dev.vars.*`, `.env`, `.env.*`; `*.example` files are fine)
   - Do not read, create, edit, copy, `cat`, `grep`, or `ls` them, and never print secret values. A hook in `.claude/settings.json` blocks this.
   - When a secret needs to be set (locally or in production, e.g. `wrangler secret put`), give the user step-by-step instructions and let them do it.
   - Keep `*.example` files up to date with variable names and dummy values only.
   - The hook also blocks shell commands whose text contains those file names. If a commit message or PR body must mention them, write the text to a file first (Write tool) and pass it with `git commit -F <file>` / `--body-file <file>`.
