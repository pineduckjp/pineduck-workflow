# pineduck-workflow

GitHub の **Issue で計画を立て、PR で開発を進める** ための、PineDuck 共通の開発ワークフローです。
どのプロジェクトでも、このリポジトリを AI (Claude Code など) に読み込ませれば、同じ手順で開発できます。

---

## 🔁 毎回おこなうワークフロー

機能追加・バグ修正のたびに、この順番で進めます。**人** と **AI** が交互に進めるイメージです。

| # | 誰が | やること | 成果物 |
| --- | --- | --- | --- |
| 1 | 👤 人 | つくりたいもの・直したいことを AI に指示する | 指示文 |
| 2 | 🤖 AI | Issue 案を作成する (テンプレートに沿って、実装方針・完了条件・タスクを書く) | Issue 案 (チャット上) |
| 3 | 👤 人 | Issue 案を確認し、修正を指示する or OK を出す | 承認 |
| 4 | 🤖 AI | GitHub に Issue を作成する (担当者・ラベル・Milestone を設定) | Issue `#N` |
| 5 | 🤖 AI | `develop` から作業ブランチを作成し、実装・コミットする | ブランチ・コミット |
| 6 | 🤖 AI | テスト・ビルドを確認し、`develop` 向けの PR を作成する (`Issue #N`、担当者・ラベル・Milestone を設定) | PR |
| 7 | 👤 人 | PR をレビューする。修正があれば AI に指示 → 5 に戻る | レビュー |
| 8 | 👤 人 | PR を `develop` に **Squash and merge** でマージする | — |
| 9 | 👤 人 | プレビュー環境で動作確認する | — |
| 10 | 👤 人 | 「本番リリースして」と AI に指示する | 指示文 |
| 11 | 🤖 AI | `develop` → `main` の PR を作成する (`Closes #N`) | リリース PR |
| 12 | 👤 人 | リリース PR を **Create a merge commit** でマージし、本番環境で動作確認する | Issue が自動でクローズ 🎉 |

> **ポイント**
> - AI は勝手に **マージ・Issue のクローズ・`main` への push をしません**。それは人の仕事です。
> - マージ方法は **`develop` へは Squash and merge、`main` へは Create a merge commit** です (→ [🔀 GitHub のブランチルール](#-github-のブランチルール-最初の-1-回だけ手動))。
> - AI は **シークレットファイル (`.dev.vars` / `.env` など) を見ない・触りません**。API キーなどの設定は、AI が手順を案内し、人が行います (→ [🔐 シークレットの扱い](#-シークレットの扱い))。
> - `docs` / `refactor` / `config` など機能に関わらない変更は、Issue を作らずステップ 5 から始めて OK です。
> - 迷ったら「今どのステップ？」と AI に聞けば、この表のどこにいるか答えてくれます。

### 👤 人が AI に送る指示 (コピペ用)

**ステップ 1: 作りたいものを指示する**

```text
https://github.com/pineduckjp/pineduck-workflow のワークフローに従って進めてください。
作りたいもの: 〇〇〇〇
```

**ステップ 3: Issue 案を承認する**

```text
この内容で Issue を作成して、実装まで進めてください。
```

**ステップ 7: PR に修正を依頼する**

```text
PR #N を次のように修正してください: 〇〇〇〇
```

**ステップ 10: 本番リリースを指示する**

```text
Issue #N を本番リリースしてください。
```

---

## 🆕 新しいプロジェクトに導入する (最初の 1 回だけ)

### AI に頼む場合

```text
https://github.com/pineduckjp/pineduck-workflow をこのプロジェクトに導入してください。
```

### 自分でやる場合

```bash
# 1. このリポジトリを取得 (初回のみ)
git clone https://github.com/pineduckjp/pineduck-workflow.git ~/apps/pineduck-workflow

# 2. 対象プロジェクトに導入 (--labels で feat / fix ラベルも作成)
~/apps/pineduck-workflow/install.sh ~/apps/my-project --labels

# 3. develop ブランチを作成
cd ~/apps/my-project
git switch -c develop && git push -u origin develop

# 4. Milestone (機能カテゴリー) を作成
gh api repos/{owner}/{repo}/milestones -f title="form-mail"
```

5. GitHub のブランチルールを設定 (→ [🔀 GitHub のブランチルール](#-github-のブランチルール-最初の-1-回だけ手動))

`install.sh` のオプション:

| オプション | 説明 |
| --- | --- |
| (なし) | テンプレートをコピー。既存ファイルはスキップ |
| `--labels` | `gh` で type ラベル (`feat` / `fix` / `docs` / `style` / `refactor` / `config` / `test` / `ci`) を作成 |
| `--force` | 既存のテンプレートファイルを上書き |

導入すると、プロジェクトの `AGENTS.md` / `CLAUDE.md` にワークフロー規約が追記されます。
以降は、そのプロジェクトで AI に指示するだけで、このワークフローに沿って動きます。

導入後、必要に応じてプロジェクト固有の内容を調整してください。

- `.github/ISSUE_TEMPLATE/fix.md` の「環境情報」
- `.github/pull_request_template.md` のチェックリスト (例: `npm run build` などの具体的なコマンド)
- CI / デプロイの workflow (`develop` → プレビュー、`main` → 本番) はプロジェクトごとに作成

## 🛡️ シークレットの混入防止 (commit / push 時)

環境変数ファイルや API キーを、うっかり Git に入れないための仕組みです。

| 仕組み | 内容 |
| --- | --- |
| `.githooks/pre-commit` | ステージ済みの変更を検査する |
| `.githooks/pre-push` | push するコミットを検査する (途中で追加して後で消したファイルも、履歴にあれば検出) |
| `.githooks/check-secrets.sh` | 検査の本体。シークレットらしいファイル名 (`.env*`、`.dev.vars*`、秘密鍵など。`*.example` は除く)、API キーの形の文字列 (Resend、Supabase、GitHub、AWS など)、ローカルのシークレットファイルが `.gitignore` で無視されているか、を調べる |
| `.claude/hooks/guard-git.sh` | Claude Code 用。`git add -A` / `git add .` / `git add -u` / `git commit -a` / `--no-verify` を止め、commit / push の前に検査を実行する |

- `install.sh` が、これらをコピーし、`core.hooksPath` を `.githooks` に設定します。**新しくクローンしたときは、`git config core.hooksPath .githooks` を実行してください**
- 検出されたら、該当のファイルを外すか `.gitignore` に追加します。すでに push した場合は、**先にキーを再発行**してください (履歴を消しても、すでに見られた可能性があるため)
- 完全な防御ではありません。検査にかからない形のキーもあります。`git diff --cached` で中身を見る習慣を持ってください

## 🔀 GitHub のブランチルール (最初の 1 回だけ・手動)

マージ方法を間違えないよう、GitHub の **Rulesets** でブランチごとにマージ方法を固定します。

| マージ先 | マージ方法 | 理由 |
| --- | --- | --- |
| `develop` | **Squash and merge** | 作業ブランチの細かいコミットを 1 つにまとめ、`develop` の履歴を「1 PR = 1 コミット」にする |
| `main` | **Create a merge commit** | `develop` のコミットをそのまま `main` に取り込む。スカッシュすると `main` と `develop` の履歴が分かれ、次回以降のリリース PR で差分や競合が出る |

> Rulesets は **Public リポジトリ**、または **GitHub Pro / Team 以上** の Private リポジトリで使えます。無料プランの Private リポジトリでは使えないため、その場合は上の表のマージ方法を守って手動で運用してください (PR テンプレートにも記載しています)。

### 1. マージ方法を許可する

リポジトリの **Settings → General → Pull Requests**

- ☑ **Allow merge commits**
- ☑ **Allow squash merging** → Default commit message: **Pull request title** (PR タイトルがそのままコミットメッセージになる)
- ☐ Allow rebase merging (使わないのでオフ)
- (任意) ☑ Automatically delete head branches: マージ後に作業ブランチを自動で削除する。`develop` は下の Ruleset で削除を禁止するので消えません

### 2. `develop` の Ruleset を作る

**Settings → Rules → Rulesets → New ruleset → New branch ruleset**

| 項目 | 設定 |
| --- | --- |
| Ruleset Name | `develop` |
| Enforcement status | **Active** |
| Target branches | Add target → Include by pattern → `develop` |
| Restrict deletions | ☑ |
| Block force pushes | ☑ |
| Require a pull request before merging | ☑ (Required approvals は 1 人開発なら `0`) |
| └ Allowed merge methods | **Squash** のみ |

最後に **Create** を押します。

### 3. `main` の Ruleset を作る

手順 2 と同じ内容で、次の項目だけ変えます。

| 項目 | 設定 |
| --- | --- |
| Ruleset Name | `main` |
| Target branches | Add target → Include default branch (または Include by pattern → `main`) |
| └ Allowed merge methods | **Merge** のみ |

### 4. 確認

- `develop` 向けの PR を開くと、マージボタンが **Squash and merge** だけになっている
- `develop` → `main` の PR を開くと、マージボタンが **Create a merge commit** だけになっている
- `main` / `develop` に直接 push しようとすると拒否される

> CI (テストなど) を PR で実行している場合は、各 Ruleset で **Require status checks to pass** にそのジョブを追加すると、テストが通らない PR をマージできなくなります。

---

## 📚 ルール早見表

| 項目 | ルール | 例 |
| --- | --- | --- |
| Issue が必要な変更 | `feat` (機能追加) / `fix` (バグ修正) | — |
| ブランチ名 | `<type>/issue-<番号>-<milestone>` | `feat/issue-3-form-mail` |
| ブランチ名 (Issue なし) | `<type>/<短い説明>` | `docs/update-readme` |
| コミット | Conventional Commits + 本文に `Issue #<番号>` | `feat: メール通知を追加` |
| `develop` 向け PR | 本文に `Issue #<番号>` (Issue は開いたまま) | `Issue #3` |
| Issue / PR の属性 | 担当者 (自分)・ラベル (`<type>`)・Milestone を必ず設定 | `feat` / `form-mail` |
| `main` 向け PR | 本文に `Closes #<番号>` (マージで自動クローズ) | `Closes #3` |
| `develop` へのマージ方法 | **Squash and merge** (1 PR = 1 コミット) | — |
| `main` へのマージ方法 | **Create a merge commit** (`develop` と履歴を揃える) | — |

`<type>` の一覧: `feat` / `fix` / `docs` / `style` / `refactor` / `config` / `test` / `ci`

詳しくは [template/CONTRIBUTING.md](./template/CONTRIBUTING.md) を参照してください。

---

## 🔐 シークレットの扱い

API キーなどのシークレットは **人だけが扱います**。AI は見ない・作らない・編集しません。

| | 誰が | どうやって |
| --- | --- | --- |
| ローカル (`.dev.vars` / `.env`) | 👤 人 | `.dev.vars.example` などをコピーして、自分で値を書く |
| 本番 (`wrangler secret put` など) | 👤 人 | AI が案内するコマンドを自分のターミナルで実行する |
| サンプル (`*.example`) | 🤖 AI | 変数名とダミー値だけを書いて管理する |

導入すると `.claude/settings.json` に次の設定が入り、Claude Code からのアクセスがブロックされます。

- `permissions.deny`: 代表的なシークレットファイル名の Read / Edit を禁止
- `hooks.PreToolUse`: `.dev.vars*` / `.env*` (`*.example` を除く) を対象とする Read / Edit / Write / Grep / Glob / Bash をブロック。判定処理は `settings.json` の中に直接書いてあるため、ブランチを切り替えても止まりません

**おすすめ**: 同じ設定をユーザー設定 (`~/.claude/settings.json`) にも入れておくと、`.claude/settings.json` がまだ無いブランチやプロジェクトでも保護が効きます。AI に「シークレット保護をユーザー設定にも入れて」と頼めば追加してくれます。

> フックは「うっかり」を防ぐガードレールです。完全な防御ではないので、本物のキーをコードやコミットに含めないよう、人も注意してください。

---

## 🤖 AI エージェントへ

このリポジトリの URL を渡されたら、次のように動いてください。

1. 作業中のプロジェクトにワークフローが未導入 (`.github/ISSUE_TEMPLATE/feat.md` が無い、または `AGENTS.md` / `CLAUDE.md` に `Development Workflow (Issue + PR)` が無い) なら、導入を提案する。
   導入は、このリポジトリを clone して `install.sh <project-dir> --labels` を実行し、「導入後の設定」を行う。
   GitHub のブランチルールは人が手動で設定するので、「🔀 GitHub のブランチルール」の手順を案内する。
2. 開発の依頼であれば、[template/AGENTS.workflow.md](./template/AGENTS.workflow.md) の規約と、上の「毎回おこなうワークフロー」の表に従う。
   今どのステップにいるかを、ユーザーに伝えながら進める。

---

## 📁 このリポジトリの中身

```text
template/                       ← 各プロジェクトにコピーされるもの
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── feat.md             # 機能追加の Issue テンプレート
│   │   ├── fix.md              # バグ修正の Issue テンプレート
│   │   └── config.yml
│   └── pull_request_template.md
├── .claude/
│   ├── settings.json           # シークレットファイルへのアクセス禁止 (権限設定 + フック)
│   └── hooks/guard-git.sh      # git add -A などを止め、commit / push 前に混入を検査 (Claude Code 用)
├── CONTRIBUTING.md             # 人向けの詳しい開発フロー
└── AGENTS.workflow.md          # AI 向けの規約 (AGENTS.md / CLAUDE.md に追記される)
install.sh                      # 導入スクリプト
```

ワークフローを変更したいときは、このリポジトリを更新し、各プロジェクトで `install.sh --force` を実行してください。
(`AGENTS.md` / `CLAUDE.md` への追記部分は自動で置き換わらないため、手動で更新してください)
