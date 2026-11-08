
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
   - **PR checkboxes mean "done by merge time".** In the PR body, use checkboxes only for work that is finished when the PR is merged. Put anything not needed at merge time (pre-release checks, post-merge / post-deploy checks, future work, items waiting on the user) in the plain bulleted `今後のタスク (マージ時には不要)` section, without checkboxes, and keep those items in the Issue's tasks. Never leave a PR with permanently unchecked boxes.
5. **Release PR `develop` → `main`** only when the user asks. Body contains `Closes #<id>`. Set assignee / label / milestone the same way.
   - Merge methods (the user merges): PRs to `develop` → **Squash and merge**; `develop` → `main` → **Create a merge commit** (squashing would make `main` and `develop` diverge). Remind the user of the method when handing over a PR.
   - Branch rules (GitHub Rulesets) are set manually by the user. Do not change repository settings; point them to the "🔀 GitHub のブランチルール" section of the pineduck-workflow README instead.
6. Do not merge PRs, close Issues, or push to `main` without the user's explicit instruction.
7. **Never touch secret files** (`.dev.vars`, `.dev.vars.*`, `.env`, `.env.*`; `*.example` files are fine)
   - Do not read, create, edit, copy, `cat`, `grep`, or `ls` them, and never print secret values. A hook in `.claude/settings.json` blocks this.
   - When a secret needs to be set (locally or in production, e.g. `wrangler secret put`), give the user step-by-step instructions and let them do it.
   - Keep `*.example` files up to date with variable names and dummy values only.
   - The hook also blocks shell commands whose text contains those file names. If a commit message or PR body must mention them, write the text to a file first (Write tool) and pass it with `git commit -F <file>` / `--body-file <file>`.
8. **Stage files explicitly and check for secrets before every commit and push** (this rule is strict)
   - Never use `git add -A`, `git add .`, `git add -u`, or `git commit -a`. Add each file by path, then run `git status` and `git diff --cached --name-only` and read the list before committing.
   - Before creating a work branch, check that the base branch's `.gitignore` already ignores the secret files. If a local secret file exists and is not ignored, stop and tell the user.
   - Before `git push`, check the outgoing files (`git log @{u}..HEAD --name-only`, or `git log HEAD --not --remotes --name-only` for a new branch). Files added and later deleted still count, because they stay in history.
   - `.githooks/check-secrets.sh` (pre-commit / pre-push) and `.claude/hooks/guard-git.sh` enforce this. Never bypass them (`--no-verify`, changing `core.hooksPath`).
   - If a secret may have been committed or pushed, stop at once and tell the user: the key must be rotated first, and history cleanup needs their decision. Do not try to hide or rewrite it silently.
   - A new clone needs `git config core.hooksPath .githooks`.
