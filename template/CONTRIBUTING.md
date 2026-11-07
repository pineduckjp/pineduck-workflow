# 貢献

このドキュメントでは、このプロジェクトの開発の進め方を説明します。
**GitHub の Issue で計画を立て、PR で実装を進める** ことを基本とします。

## 大前提

ブランチの `<type>` によって、作業の流れが異なります。

`<type>` は以下のいずれかを指定してください。

- `feat`: 機能追加
- `fix`: バグ修正
- `docs`: ドキュメント関連
- `style`: コードのフォーマット修正・コメント追加・画面の見た目の修正(機能に関わらない変更)
- `refactor`: コード構造の改善
- `config`: 設定ファイルの変更
- `test`: テストコードの追加・修正
- `ci`: CI/CD 設定の変更

あらかじめ Milestone を作成してください。Milestone は機能カテゴリーとして使用します。`form-mail` のように、ハイフン区切りで作成してください。

## ブランチ構成

| ブランチ | 用途 |
| --- | --- |
| `main` | 本番リリース用 |
| `develop` | プレビュー確認用。作業ブランチはここへマージする |
| `<type>/...` | 作業ブランチ。`develop` から作成する |

## マージ方法

| マージ先 | マージ方法 | 理由 |
| --- | --- | --- |
| `develop` | **Squash and merge** | 作業ブランチのコミットを 1 つにまとめ、「1 PR = 1 コミット」にする |
| `main` | **Create a merge commit** | `develop` の履歴をそのまま取り込む。スカッシュすると `main` と `develop` の履歴が分かれ、次回以降のリリース PR で差分や競合が出る |

可能であれば GitHub の Rulesets でブランチごとにマージ方法を固定してください (手順: [pineduck-workflow の README](https://github.com/pineduckjp/pineduck-workflow#-github-のブランチルール-最初の-1-回だけ手動))。

## 開発の流れ

### 1. Issue 作成（計画）

`<type>` が `feat` または `fix` の場合、Issue を作成してください。それ以外の(機能に関わる編集を行っていない)場合は、Issue 作成は不要です。

Issue 作成時に、テンプレートを使用してください。Issue の「実装方針」「完了条件」「タスク」が、そのまま作業計画になります。

- **機能追加**: [feat.md](./.github/ISSUE_TEMPLATE/feat.md)
- **バグ修正**: [fix.md](./.github/ISSUE_TEMPLATE/fix.md)

Issue には **担当者・ラベル (`<type>`)・Milestone** を設定してください。

### 2. 作業開始

1. `develop` を最新化: `git switch develop && git pull`
2. ブランチ作成: `git switch -c <type>/issue-<issue-id>-<milestone-name>`
   - Issue がない場合: `<type>/<short-description>`
3. コード編集
4. コミット
5. push

コミットメッセージは、[Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/) を参考にしてください。

```text
<type>: <commit-message>

Issue #<issue-id>
```

このようなコミットメッセージを作成してください。

```text
feat: 問い合わせ内容のメール通知を追加

Issue #1
```

Issue を作成していない場合は、`Issue #<issue-id>` の記載は不要です。

```text
docs: README.md の更新
```

過去の実装に対する破壊的な変更を行った場合は、`<type>!: <commit-message>` のように、`!` を付与してください。

```text
refactor!: API のレスポンス形式を変更
```

### 3. develop ブランチへマージ

1. PR 作成: `Issue #<issue-id>` を記載(Issue を作成していない場合は不要)
2. レビュー・承認
3. マージ (**Squash and merge**)
4. (設定している場合) プレビュー環境へ自動デプロイ

PR 作成時に、テンプレートを使用してください。

- [PR テンプレート](./.github/pull_request_template.md)

PR にも **担当者・ラベル (`<type>`)・Milestone (Issue と同じもの)** を設定してください。

完了した Issue のタスクにチェックを入れてください。

**PR のチェックボックスは、「マージ時までに終わっているもの」だけにします。** マージ時にやる必要のない作業(リリース前の確認、マージ後・デプロイ後の確認、今後の作業、他の人の対応待ちなど)は、PR の「今後のタスク (マージ時には不要)」に、チェックボックスなしの箇条書きで書いてください。それらは Issue のタスクにも残します。チェックが入らないまま残るボックスがあると、マージしてよいのか判断しにくくなるためです。

### 4. プレビュー確認

1. プレビュー環境で動作確認
2. 問題なし → 次へ

### 5. main ブランチへマージ

1. PR 作成(`develop` → `main`): `Closes #<issue-id>` を記載(Issue を作成していない場合は不要)
2. レビュー・承認
3. マージ (**Create a merge commit**)
4. (設定している場合) 本番環境へ自動デプロイ

作業ブランチは、マージ後に削除してください。

### 6. 本番確認

1. 本番環境で動作確認
2. Issue 自動クローズ

🎉 完了

## シークレットの扱い

API キーなどのシークレットは **人だけが扱います**。AI (Claude Code など) には見せず、触らせません。

- ローカル: `.dev.vars.example` (または `.env.example`) をコピーして、自分で値を書く。ファイルは git 管理外
- 本番: `wrangler secret put <NAME>` などを自分のターミナルで実行する
- `*.example` にはダミー値だけを書く
- `.claude/settings.json` のフックで、Claude Code からシークレットファイルへのアクセスをブロックしている
