# スキルの一覧

- このdotfilesで入れているスキルと、dotfilesの外から入ってくるスキルをまとめる
- 入れ方の仕組みは[ai.md](ai.md)を読む
- `ai/skills.txt`や`ai/plugins.txt`を変えたら、この一覧も合わせて更新する

## 見方

- **呼ばれ方**
  - 自動：話の流れに合うと、エージェントが自分で使う。`/名前`で明示的に呼ぶこともできる
  - /で呼ぶ：`/名前`と入力したときだけ動く
- **呼び方の違い**
  - Claude Code：`/名前`。プラグインのスキルは`/プラグイン名:名前`
  - Codex：`$名前`。プラグインのスキルは`$プラグイン名:名前`
- **場所**
  - 共通の置き場所：`~/.agents/skills/<名前>`
  - Claude Code：`~/.claude/skills/<名前>`（`~/.ai/<アカウント>/claude/skills/`にも同じリンク）
  - Claude Codeのプラグイン：`~/.claude/plugins/cache/<配布元>/<プラグイン>/<バージョン>/`
  - Codexのプラグイン：`~/.codex/plugins/cache/<配布元>/<プラグイン>/`

## 1. dotfilesで入れているスキル

### 1.1 `ai/skills.txt`：1つずつ入れているスキル

- 対象：Claude CodeとCodexの両方、すべてのアカウント
- 実体：`~/.local/share/dotfiles/skill-repos/<owner>/<repo>/skills/<名前>/`
- 更新：`./ai/install.sh`を実行すると最新になる

#### ドキュメント・ファイル（Anthropic）

| スキル | 内容 | 呼ばれ方 | 配布元 |
| --- | --- | --- | --- |
| docx | Wordファイルの作成・読み取り・編集。目次、見出し、変更履歴、コメントも扱える | 自動 | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/docx) |
| pptx | PowerPointのスライドの作成・読み取り・編集。テンプレートやスピーカーノートも扱える | 自動 | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/pptx) |
| xlsx | Excel・CSVの作成・読み取り・編集。数式、書式、グラフ、汚れたデータの整理 | 自動 | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/xlsx) |
| pdf | PDFの読み取り・結合・分割・作成、フォームの入力、OCRなど | 自動 | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/pdf) |
| doc-coauthoring | 仕様書・提案書・設計判断の文書を、対話しながら一緒に書き上げる。前提の共有→推敲→読み手の視点での確認の順に進む | 自動 | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/doc-coauthoring) |

#### デザイン・フロントエンド

| スキル | 内容 | 呼ばれ方 | 配布元 |
| --- | --- | --- | --- |
| frontend-design | UIを作るときに、ありがちなテンプレートの見た目にならないよう、配色・タイポグラフィ・全体の方向性を意図して決める | 自動 | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design) |
| web-design-guidelines | UIのコードを、VercelのWeb Interface Guidelines（アクセシビリティ、UXなど）に照らしてレビューし、`ファイル:行`の形式で指摘する。ガイドラインは毎回最新をWebから取得する | 自動 | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines) |

#### スキル探し

| スキル | 内容 | 呼ばれ方 | 配布元 |
| --- | --- | --- | --- |
| find-skills | 「〇〇するスキルはある？」と聞いたときに、[skills.sh](https://skills.sh/)や`npx skills find`で公開されているスキルを探す | 自動 | [vercel-labs/skills](https://github.com/vercel-labs/skills/tree/main/skills/find-skills) |

- find-skillsは、見つけたスキルを`npx skills add`で直接入れようとする
  - そのまま入れると、dotfilesの宣言に残らない
  - 使い続けたいスキルが見つかったら、`ai/skills.txt`に書いて`./ai/install.sh`で入れる

### 1.2 `ai/plugins.txt`：プラグインとして入れているもの

- 対象：CLIごと・アカウントごとに導入する
- 更新：`claude plugin update <プラグイン>`、`codex plugin marketplace upgrade`

#### Superpowers

- 配布元：[obra/superpowers](https://github.com/obra/superpowers)
- 対象：Claude Code、Codex（どちらも`claude-plugins-official`から入れる）
- 設計→計画→実装→レビューを、決まった手順で進めるためのスキル集
- すべて自動で呼ばれる。Claude Codeでは`/superpowers:名前`

| スキル | 内容 |
| --- | --- |
| using-superpowers | 会話の始めに、使えるスキルを探して使うよう促す。Superpowers全体の入口 |
| brainstorming | 機能やコンポーネントを作る前に、目的・要件・設計を対話で詰める |
| writing-plans | 仕様をもとに、コードに触る前に実装計画を書く |
| executing-plans | 書いた実装計画を、確認の区切りを入れながら別のセッションで実行する |
| subagent-driven-development | 独立したタスクをサブエージェントに任せ、成果をレビューしながら計画を進める |
| dispatching-parallel-agents | 依存関係のない2つ以上のタスクを、並列のエージェントに振り分ける |
| test-driven-development | 実装コードより先にテストを書く |
| systematic-debugging | バグやテストの失敗を、修正案を出す前に原因から順に調べる |
| verification-before-completion | 「終わった」「直った」と言う前に、確認のコマンドを実際に実行して結果を示す |
| requesting-code-review | 大きな機能の実装後やマージ前に、要件を満たしているかのレビューを依頼する |
| receiving-code-review | レビューの指摘を鵜呑みにせず、技術的に検証してから対応する |
| using-git-worktrees | 作業を始める前に、git worktreeで今の作業場所から切り離す |
| finishing-a-development-branch | 実装とテストが終わったブランチを、どう取り込むか判断する |
| writing-skills | スキルを作る・直す・動くか確かめる |

#### mattpocock-skills

- 配布元：[mattpocock/skills](https://github.com/mattpocock/skills)（`claude-plugins-official`経由）
- 対象：Claude Code、Codex
- Claude Codeでは`/mattpocock-skills:名前`

| スキル | 内容 | 呼ばれ方 |
| --- | --- | --- |
| diagnosing-bugs | 難しいバグや遅さの原因を、仮説と検証を繰り返して突き止める | 自動 |
| tdd | テストを先に書いて実装する（red → green → refactor） | 自動 |
| prototype | 設計を確かめるための使い捨ての試作を作る | 自動 |
| research | 公式ドキュメントなど信頼できる情報源で調べ、Markdownにまとめる | 自動 |
| domain-modeling | 用語集（CONTEXT.md）や設計判断の記録（ADR）を作る | 自動 |
| codebase-design | モジュールの境界やインターフェースの設計を考える | 自動 |
| code-review | 指定したコミット以降の差分を、規約と仕様の2つの観点でレビューする | 自動 |
| resolving-merge-conflicts | mergeやrebaseのコンフリクトを解消する | 自動 |
| wizard | 人が手でやる手順（認証情報の設定など）を案内する対話式のスクリプトを作る | 自動 |
| grilling | 計画や考えに次々と質問をぶつけて、穴を探す | 自動 |
| writing-for-agents | スキルやCLAUDE.mdなど、AI向けの文書の書き方 | 自動 |
| grill-me | 計画を質問攻めにする | /で呼ぶ |
| grill-with-docs | 計画を質問攻めにしながら、ADRと用語集も残す | /で呼ぶ |
| to-spec | 会話の内容を仕様書にまとめ、issueトラッカーに登録する | /で呼ぶ |
| to-tickets | 計画や仕様を、依存関係つきのチケットに分ける | /で呼ぶ |
| implement | 仕様やチケットをもとに実装する | /で呼ぶ |
| triage | issueやPRを分類して、AIが取りかかれる形に整える | /で呼ぶ |
| wayfinder | 1回のセッションに収まらない大きな作業を、判断ごとのチケットに分けて進める | /で呼ぶ |
| improve-codebase-architecture | コードベースの改善点を洗い出してHTMLのレポートにする | /で呼ぶ |
| setup-matt-pocock-skills | 上のスキルを使う前に、リポジトリの初期設定をする | /で呼ぶ |
| handoff | 会話を要約して、別のエージェントへの引き継ぎ文書にする | /で呼ぶ |
| teach | 新しい概念を教えてもらう | /で呼ぶ |
| to-questionnaire | 自分では決められないことを、他の人に聞く質問票にする | /で呼ぶ |
| wait-what | 直前の説明が分からなかったときに、言い直してもらう | /で呼ぶ |
| ask-matt | どのスキルを使えばいいか相談する | /で呼ぶ |

#### codex

- 配布元：[openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc)
- 対象：Claude Code、Codex（Claude CodeからCodexに作業を頼むためのもの。Codexにも元から入っていたので、そのままにしている）
- 中のスキル（codex-cli-runtimeなど3つ）は内部用で、主にコマンドから使う

| コマンド | 内容 |
| --- | --- |
| /codex:rescue | 調査や修正をCodexに任せる |
| /codex:review | 手元の変更をCodexにレビューさせる |
| /codex:adversarial-review | 実装方針や設計判断にあえて異を唱えるレビューをさせる |
| /codex:status、/codex:result、/codex:cancel | Codexに任せた作業の状況確認・結果表示・中止 |
| /codex:transfer | 今のClaude Codeのセッションを、Codexのスレッドとして引き継ぐ |
| /codex:setup | Codex CLIが使えるか確認する |

#### clangd-lsp

- 配布元：[claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/clangd-lsp)
- 対象：Claude Code、Codex
- C/C++の補完や定義ジャンプを使えるようにする。スキルは含まない

### 1.3 `ai/skills/`：自作スキル

- まだない
- 作り方は[ai/skills/README.md](../ai/skills/README.md)

## 2. dotfilesの外から入ってくるスキル

- ここにあるスキルは、dotfilesでは管理していない
- 外したいときは、それぞれの場所で設定する

### 2.1 claude.aiのアカウントから同期されるスキル

- 場所：`~/.claude/skills/synced/`
- ログインしているclaude.aiのアカウントで有効にしたスキルが、Claude Codeに同期される
- 外すとき：claude.aiの設定でスキルをオフにする（Coworkからも消える）

| スキル | 内容 |
| --- | --- |
| docx、pptx、xlsx、pdf | 1.1と同じ。Claude Codeでは1.1の方が`/名前`になり、こちらは`/anthropic-skills:名前` |
| docs | claude.ai上で共有・コメント・編集ができるドキュメントを作る |
| skill-creator | スキルを作る、改善する、評価する |
| morning | 朝のブリーフィングを作る |
| import-memory | 他のAIのメモリをClaudeに取り込む |

### 2.2 Claude Codeに最初から入っているスキル

- 外せない。同じ名前のスキルを`~/.claude/skills/`に置くと置き換わる
- 例：`/code-review`、`/simplify`、`/security-review`、`/loop`、`/schedule`、`/init`、`/run`、`/update-config`、`/claude-api`、`/dataviz`

### 2.3 Codexに最初から入っているスキルとプラグイン

- スキル（場所：`~/.codex/skills/.system/`）
  - imagegen：画像を生成・編集する
  - openai-docs：CodexやOpenAIのAPIについて調べる
  - skill-creator、skill-installer、plugin-creator：スキルやプラグインを作る・入れる
  - review-agent：変更を読み取り専用でレビューする
- プラグイン（OpenAIが配布）
  - documents、pdf、Presentations、Spreadsheets：Word、PDF、スライド、表計算
  - template-creator：資料からテンプレートのスキルを作る
  - browser：アプリ内のブラウザを操作する
  - sites：Webサイトを作って公開する
  - visualize：図や表を会話の中で作る

### 2.4 Cursorが置いたスキル

- 場所：`~/.agents/skills/`（共通の置き場所と同じ）
- Codexにも見えているが、Cursor向けの内容なのでClaude Codeにはリンクしていない
- 元から入っていたものなので、消さずにそのままにしている
- automate、babysit、canvas、create-hook、create-rule、create-skill、create-subagent、env-setup、loop、migrate-to-skills、onboard、review、review-bugbot、review-security、sdk、shell、split-to-prs、statusline、update-cli-config、update-cursor-settings

### 2.5 Claude Desktopアプリ（Cowork）

- `~/.claude/skills/`を読まないので、dotfilesで入れたスキルは出てこない
- ログインしているclaude.aiのアカウント（個人・会社）で有効にしたスキルだけが使える
- 会社のアカウントで作ったスキルは、このリポジトリには書かない
