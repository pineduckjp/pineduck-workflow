# github-workflow-template

GitHub の **Issue で計画を立て、PR で開発を進める** ワークフローを、どのプロジェクトにも導入できるテンプレート集です。
[pineduckjp/pineduck](https://github.com/pineduckjp/pineduck) の `.github` テンプレートと `CONTRIBUTING.md` を元に、特定の技術スタックに依存しない形にしています。

## 含まれるもの

```text
template/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── feat.md          # 機能追加 (概要 / 背景 / 実装方針 / 完了条件 / タスク)
│   │   ├── fix.md           # バグ修正 (再現手順 / 原因 / 修正方針 / タスク)
│   │   └── config.yml
│   └── pull_request_template.md
├── CONTRIBUTING.md          # 人間向けの開発フロー
└── AGENTS.workflow.md       # AI エージェント (Claude Code など) 向けの規約。AGENTS.md / CLAUDE.md に追記される
install.sh                   # 対象プロジェクトへ導入するスクリプト
```

## ワークフロー概要

```text
Issue 作成 (計画) ─▶ 作業ブランチ ─▶ PR → develop (Issue #N) ─▶ プレビュー確認 ─▶ PR → main (Closes #N) ─▶ 本番確認
```

- `feat` / `fix` は必ず Issue を作成し、Issue の「実装方針」「完了条件」「タスク」を計画として使います。
- ブランチ名: `<type>/issue-<issue-id>-<milestone-name>`
- コミット: Conventional Commits + 本文に `Issue #<issue-id>`
- 詳細は [template/CONTRIBUTING.md](./template/CONTRIBUTING.md) を参照してください。

## 使い方

```bash
# 対象プロジェクトに導入 (既存ファイルはスキップ)
./install.sh ~/apps/my-project

# feat / fix ラベルも作成する (gh CLI のログインが必要)
./install.sh ~/apps/my-project --labels

# 既存のテンプレートを上書きする
./install.sh ~/apps/my-project --force
```

`AGENTS.md` / `CLAUDE.md` にはワークフロー規約が追記されます (再実行しても重複しません)。どちらも無い場合は `AGENTS.md` を新規作成します。

## 導入後の設定

1. `develop` ブランチを作成して push する
   ```bash
   git switch -c develop && git push -u origin develop
   ```
2. Milestone (機能カテゴリー) を作成する
   ```bash
   gh api repos/{owner}/{repo}/milestones -f title="form-mail"
   ```
3. ラベル `feat` / `fix` を作成する (`--labels` を使った場合は不要)
4. 必要に応じて、プロジェクト固有の内容を調整する
   - `fix.md` の「環境情報」
   - `pull_request_template.md` のチェックリスト (例: `npm run build` などの具体的なコマンド)
   - CI / デプロイの workflow (`develop` → プレビュー、`main` → 本番) はプロジェクトごとに作成してください

## develop ブランチを使わないプロジェクトの場合

`main` のみで運用する場合は、PR テンプレートと `CONTRIBUTING.md` の develop に関する記述を削除し、PR 本文に `Closes #<issue-id>` を記載してください。
