# Claude CodeとCodexの管理

- このドキュメントでは、AIコーディングエージェント（Claude CodeとCodex）をこのdotfilesでどう管理しているかを説明する
- 前半は**使い方**、後半は**仕組み**
- 入れているスキルの一覧と内容は[skills.md](skills.md)にある

## 1. 用語

| 用語 | 意味 |
| --- | --- |
| スキル | `SKILL.md`を1つ含むフォルダ。「いつ使うか」と「どう進めるか」が書いてあり、エージェントが必要に応じて読む。書式はClaude CodeとCodexで共通 |
| プラグイン | 複数のスキル、フック、コマンド、LSPなどをまとめて配るための入れ物 |
| マーケットプレイス | プラグインの配布元。GitHubのリポジトリなど |
| 共通の指示 | エージェントが、どのプロジェクトでも最初に読む指示ファイル。Claude Codeは`CLAUDE.md`、Codexは`AGENTS.md` |
| アカウント | ログイン情報や履歴を別々に持つための設定フォルダ。既定は`~/.claude`と`~/.codex`、それ以外は`~/.ai/<名前>/` |

## 2. 管理しているもの

| 何を | このリポジトリのファイル | 届く場所 | 対象 |
| --- | --- | --- | --- |
| 本体 | `Brewfile`（Codex）、`install.sh`（Claude Code） | `/opt/homebrew/bin/codex`、`~/.local/bin/claude` | このMac |
| 共通の指示 | `ai/AGENTS.md` | 各アカウントの`CLAUDE.md`、`AGENTS.md` | 両方の全アカウント |
| Claude Codeの設定 | `ai/claude/settings.json` | 各アカウントの`settings.json`（リンクではなく、内容を書き込む） | Claude Codeの全アカウント |
| プラグイン | `ai/plugins.txt`、`ai/marketplaces.txt` | 各アカウントの`plugins/` | 両方の全アカウント |
| スキル（GitHubから） | `ai/skills.txt` | `~/.agents/skills/`、各アカウントの`skills/` | 両方の全アカウント |
| スキル（自作） | `ai/skills/<名前>/` | 同上 | 両方の全アカウント |
| MCPサーバー | `ai/mcp.txt` | Claude Codeの各アカウントの`.claude.json`、Codexの`config.toml` | 両方の全アカウント |
| アカウントの切り替え | `zsh/.config/zsh/ai.zsh` | シェルのコマンド | このMac |

- 今あるアカウント
  - **既定（personal）**：Claude CodeとCodex
  - **neoai**：Claude Codeだけ

## 3. コマンド

### 3.1 状態を揃える・確かめる

| コマンド | やること |
| --- | --- |
| `./ai/install.sh` | `ai/`の宣言を読んで、指示・設定・プラグイン・スキルを入れる。足りないものだけを入れる |
| `ai-update` | 本体、プラグイン、スキルをまとめて最新にする |
| `ai-doctor` | 全アカウントが宣言どおりになっているかを確かめる |

- `ai-doctor`の表示
  - `✓`：宣言どおり
  - `✗`：問題あり。Claude Codeの設定がdotfilesと違う、スキルが足りない、など。多くは`./ai/install.sh`で直る
  - `⚠`：注意。宣言にないプラグインが入っている、など
  - `・`：参考情報。他のツールが置いたスキルなど

### 3.2 アカウント

| コマンド | やること |
| --- | --- |
| `claude`、`codex` | 既定のアカウントで起動する |
| `claude-<名前>`、`codex-<名前>` | そのアカウントで起動する（例：`claude-neoai`） |
| `ai <名前> <コマンド>` | そのアカウントで、コマンドを1回だけ実行する |
| `ai-use <名前>` | 今のシェル全体を、そのアカウントに切り替える。プロンプトにアカウント名が出る |
| `ai-ls` | アカウントと、それぞれの保存先の一覧 |
| `ai-new <名前> [claude] [codex]` | アカウントを作る。CLIを省略すると両方 |

## 4. やりたいこと別の手順

### スキルを追加する

1. [skills.md](skills.md)や`find-skills`で、入れたいスキルを探す
2. 置き場所を決める
   - GitHubにあるスキルを1つだけ入れる → `ai/skills.txt`に`<owner/repo> <スキルのフォルダ>`を1行足す
   - 複数のスキルやフックがプラグインとして配られている → `ai/plugins.txt`に1行足す
   - 自分で書く → `ai/skills/<名前>/SKILL.md`を作る（書き方は`ai/skills/README.md`）
3. `./ai/install.sh`を実行する
4. `docs/skills.md`に追記する

### スキルを外す

- `ai/skills.txt`から行を消して、`./ai/install.sh`を実行する
  - リンクも自動で片付く

### プラグインを外す

- `ai/plugins.txt`から行を消すだけでは消えない
- アカウントごとにコマンドで外す
  - Claude Code：`claude plugin uninstall <プラグイン>`（別のアカウントは`ai neoai claude plugin uninstall <プラグイン>`）
  - Codex：`codex plugin remove <プラグイン>`
- 消し忘れは、`ai-doctor`が「plugins.txt にありません」と教えてくれる

### MCPサーバーを追加する・外す

- 追加する：`ai/mcp.txt`に`<名前> <起動するコマンドと引数>`を1行足して、`./ai/install.sh`
  - Claude Codeの全アカウントとCodexに、同じコマンドで登録される
  - このリポジトリは公開されているので、APIキーなどが必要なサーバーは書かない。各CLIで直接登録する
- 外す：行を消したあと、アカウントごとにコマンドで外す
  - Claude Code：`claude mcp remove -s user <名前>`（別のアカウントは`ai neoai claude mcp remove -s user <名前>`）
  - Codex：`codex mcp remove <名前>`

### 共通の指示を変える

- `ai/AGENTS.md`を編集する
- 次に起動したセッションから反映される
- すべてのプロジェクトで毎回読まれるので、短く保つ
- プロジェクトごとの指示は、各リポジトリの`CLAUDE.md`や`AGENTS.md`に書く

### Claude Codeの許可のルールを変える

- どのプロジェクトでも使うもの → `ai/claude/settings.json`を編集して、`./ai/install.sh`
- そのプロジェクトだけのもの → そのリポジトリの`.claude/settings.local.json`に書く
- `/config`などで変えた設定を残したいとき
  1. `ai-doctor`で「違うキー」を見る
  2. 残したいものは`ai/claude/settings.json`にも書く
  3. `./ai/install.sh`を実行する。`ai/claude/settings.json`にない変更は、ここで元に戻る
- `./ai/install.sh`は、消える許可ルールがあると、書き込む前に一覧を表示する（止まらずに進む）

### アカウントを作る

1. `ai-new <名前> claude`（Codexも使うなら`ai-new <名前>`）
2. `exec zsh`
3. `claude-<名前>`で起動して、`/login`でログインする
4. `./ai/install.sh`で、指示・設定・プラグイン・MCPサーバー・スキルを入れる
5. `ai-doctor`で確かめる

### アカウントを消す

- `~/.ai/<名前>`を削除して、`exec zsh`

### 全部を最新にする

- `ai-update`
- 起動中のセッションには、再起動すると反映される

## 5. 仕組み

### 5.1 Stowで管理しない理由

- `~/.claude`や`~/.codex`には、設定と一緒に次のものも書き込まれる
  - 会話の履歴、セッション、ログ
  - ログインの情報
- フォルダごとGitで管理すると、差分のほとんどが履歴になり、ログインの情報まで入ってしまう
- そこで、**入れたいものを宣言しておき、`ai/install.sh`が必要なものだけをリンクやコマンドで入れる**
  - リンクするもの：自分で書いたもの（共通の指示、設定、自作スキル）
  - 名前だけを書くもの：外部のプラグインとスキル。中身をコピーすると、配布元の更新を追えなくなるため

### 5.2 本体の入れ方

| | 入れ方 | 理由 |
| --- | --- | --- |
| Claude Code | 公式のインストーラー（`curl -fsSL https://claude.ai/install.sh \| bash`） | 自動で更新される。Homebrewで入れると自動で更新されない |
| Codex | `Brewfile`の`cask "codex"` | `npm i -g`で入れると、Homebrewのnodeとvoltaでnpmの置き場所が2つに分かれてしまう |

### 5.3 アカウント

- Claude Codeは`CLAUDE_CONFIG_DIR`、Codexは`CODEX_HOME`という環境変数で、設定フォルダの場所を決める
- この値を差し替えると、ログイン情報ごと別のアカウントになる
- `ai.zsh`は、これを使ってアカウントを切り替える

```
既定（personal）   ~/.claude          ~/.codex
neoai              ~/.ai/neoai/claude  （なし → Codexは既定のアカウントを使う）
```

- アカウントは、フォルダがあるCLIだけを持つ
  - `~/.ai/`の下のフォルダを見つけて、`claude-<名前>`などのコマンドを自動で作る
  - フォルダがないCLIのコマンド（例：`codex-neoai`）は作らない
  - `ai-use neoai`で切り替えても、Codexは既定のアカウントのまま
  - `ai/install.sh`や`ai-doctor`も、フォルダがあるCLIだけを対象にする

### 5.4 共通の指示

- `ai/AGENTS.md`を、全アカウントの`CLAUDE.md`（Claude Code）と`AGENTS.md`（Codex）にリンクする
  - どちらもただのMarkdownなので、1つのファイルを両方で使える
- 書いていること
  - 日本語で答える、決めるべきことは推測せずに聞く
  - 環境（macOS、zsh、Homebrew、uv、pyenv、Volta）
  - 設定ファイルは`~/dotfiles`側を編集する
  - コミットとpushは頼まれたときだけ、秘密情報を出さない
- 読み込まれるのはセッションの起動時だけ
  - 起動中のセッションには、編集しても反映されない

### 5.5 Claude Codeの設定と許可のルール

- `ai/claude/settings.json`の内容を、全アカウントの`settings.json`に書き込む
  - **リンクにしない理由**：Claude Codeは設定を保存するとき、リンクを残さず、ファイルごと置き換える。リンクにしても、いつの間にか普通のファイルになり、dotfiles側の変更が届かなくなる
  - **書き込み方**：今の`settings.json`に、dotfilesの設定を重ねる
    - dotfilesに書いたキーは、dotfilesの値になる。配列（許可のルールなど）は丸ごと置き換わる
    - dotfilesに書いていないキー（Claude Codeが自分で足したものなど）は残る
- 入れている設定
  - 見た目：モデル、テーマ、全画面表示、通知
  - 有効にするプラグインと、その配布元
  - 許可のルール
- 許可のルールは3種類。deny → ask → allow の順に調べ、最初に当たったものが使われる

| 種類 | 意味 | 入れているもの |
| --- | --- | --- |
| deny | 実行させない | 秘密情報の読み取り：SSHの鍵、`~/.config/zsh/local/*.zsh`（実体の`~/dotfiles/zsh/.config/zsh/local/*.zsh`も）、`.env`・`.env.local`・`.env.production`など、Codex・gh・gcloud・AWS・Docker・npmの認証情報 |
| ask | allowに当たっても、必ず確認する | `git push`（すべて）、`git reset --hard`、`git clean`、`sudo` |
| allow | 確認せずに実行する | `~/`以下の読み取り、git（pushを除く）、gh、uv pip・uv venv、pytest、ruff、ty、tsc、vite、go testなど |

- 決めごと
  - **pushは毎回確認する**：外に出る操作で、取り消しにくいため。`ai/AGENTS.md`の「pushは頼まれたときだけ」とも揃えている
  - **何でも実行できる`uv run`と`go run`は許可しない**：中のコードがdenyをすり抜けて秘密情報を読めるため。テストや型チェックは許可している
  - **`.env.example`などは読める**：denyは秘密情報が入るファイル名だけに絞っている
- denyの限界
  - Claudeのファイル操作と、`cat`などの分かりやすいコマンドには効く
  - PythonやNodeのスクリプトが中で開くファイルまでは防げない
- Claude Codeは、`settings.json`を自分で書き換えることがある
  - プラグインの有効化、`/config`での変更、「次回から聞かない」を選んだときなど
  - dotfilesに書いたキーが変わると、`ai-doctor`が「違うキー」として教えてくれる

### 5.6 スキルとプラグインの届け方

#### Claude CodeとCodexでは、読む場所が違う

| | 自分用のスキルを読む場所 | プラグインが入る場所 |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | 各アカウントの`plugins/` |
| Codex | `~/.agents/skills/`（アカウントに関係なく同じ場所） | 各アカウントの`plugins/` |

- 何もしなければ、スキルはCLIごとに、プラグインはアカウントごとに入れる必要がある

#### 設計：スキルは1か所に集めて配り、プラグインは全アカウントに同じものを入れる

```
【スキル】
ai/skills.txt ─(git clone)─▶ ~/.local/share/dotfiles/skill-repos/<owner>/<repo>/
                                        │
ai/skills/<名前>/ ──────────────────────┤
                                        ▼
                             ~/.agents/skills/<名前>   ← 共通の置き場所
                                        │
                      ┌─────────────────┴──────────────────┐
                      ▼                                    ▼
                    Codex                     Claude Codeの各アカウントの skills/<名前>
                 （直接読む）                   （~/.claude/skills、~/.ai/neoai/claude/skills）

【プラグイン】
ai/plugins.txt ─(claude plugin install / codex plugin add)─▶ 各CLI × 各アカウントの plugins/

【共通の指示と設定】
ai/AGENTS.md ─────────────▶ 各アカウントの CLAUDE.md、AGENTS.md
ai/claude/settings.json ──(内容を重ねて書き込む)──▶ Claude Codeの各アカウントの settings.json
```

- スキルは`~/.agents/skills/`に集める
  - Codexはここを直接読む
  - Claude Codeには、宣言したスキルだけを各アカウントの`skills/`へもう一段リンクする
  - どちらのCLIも、どのアカウントでも、同じ実体を読む
- プラグインは、`ai/install.sh`がCLIごと・アカウントごとに同じものを入れる
  - `ai/plugins.txt`の2列目に`claude`や`codex`と書くと、そのCLIだけに絞れる
  - Codexは、`claude-plugins-official`などClaude Code向けの配布元からもプラグインを入れられる

#### どこに書くかの決め方

| 入れたいもの | 書く場所 | 理由 |
| --- | --- | --- |
| 複数のスキルやフックをまとめたプラグイン（mattpocock-skills、Superpowersなど） | `ai/plugins.txt` | フックやコマンドは、スキルの置き場所では動かない |
| GitHubにあるスキルを1つだけ（docx、frontend-designなど） | `ai/skills.txt` | プラグインで入れると、欲しくないスキルまで一緒に入ることがある |
| 自分で書いたスキル | `ai/skills/<名前>/` | 中身をこのリポジトリで管理する |

### 5.7 `ai/install.sh`がやること

1. **プラグイン**
   - 全アカウントで、`marketplaces.txt`の配布元を登録する
   - `plugins.txt`のプラグインのうち、入っていないものを入れる
2. **MCPサーバー**
   - 全アカウントに、`mcp.txt`のMCPサーバーのうち、登録されていないものを登録する
3. **スキルを集める**
   - `skills.txt`のリポジトリを`~/.local/share/dotfiles/skill-repos/`に取得する。取得済みなら最新にする
   - リポジトリ全体ではなく、宣言したスキルのフォルダだけを取り出す（git の sparse-checkout）。thesvgのように50MBあるリポジトリでも、数MBで済む
   - 各スキルと自作スキルを`~/.agents/skills/<名前>`にリンクする
4. **Claude Codeへ配る**
   - 宣言したスキルを、Claude Codeの全アカウントの`skills/`にリンクする
5. **共通の指示と設定**
   - `ai/AGENTS.md`を、全アカウントの`CLAUDE.md`と`AGENTS.md`にリンクする
   - `ai/claude/settings.json`の内容を、Claude Codeの全アカウントの`settings.json`に重ねて書き込む。消える許可ルールがあれば、先に表示する

- 安全のための決まり
  - 宣言から消したスキルのリンクは片付ける。ただし、消すのはこのdotfilesが作ったリンクだけ
  - 他のツールが置いたスキルや、同じ名前の実体のファイルは上書きしない。警告を出して飛ばす
  - 実体のファイルがあって警告が出たときは、退避してから再実行する（例：`mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.before-dotfiles`）

### 5.8 `ai-update`と`ai-doctor`がやること

- `ai-update`（`ai/update.sh`）
  1. 本体：`claude update`と`brew upgrade --cask codex`
  2. プラグイン：Claude Codeは全アカウントで配布元を更新してから、入っているプラグインを1つずつ更新する。Codexは配布元を更新する
  3. スキル：`ai/install.sh`を実行する
- `ai-doctor`（`ai/doctor.sh`）
  - 本体：`claude`と`codex`があるか、CodexがHomebrewから入っているか
  - 共通の指示：全アカウントで`ai/AGENTS.md`へのリンクになっているか
  - Claude Codeの設定：`ai/claude/settings.json`の内容が入っているか。違うときは、違うキーを表示する
  - プラグイン：宣言したものが入っているか、宣言にないものが入っていないか（claude.aiから同期されたものや、Codexに最初から入っているものは数えない）
  - MCPサーバー：宣言したものが全アカウントに登録されているか
  - スキル：宣言したものが`~/.agents/skills/`とClaude Codeの全アカウントにあるか、壊れたリンクがないか
  - 問題があれば、終了ステータス1で終わる
- 共通の処理は`ai/lib.sh`にまとめ、3つのスクリプトから読み込んでいる

## 6. dotfilesの外から入ってくるもの

- 次のものは、このdotfilesでは管理していない

| 入ってくるもの | 場所 | 対象 | 補足 |
| --- | --- | --- | --- |
| claude.aiのアカウントのスキルとプラグイン | `~/.claude/skills/synced/`など | Claude Code | ログインしているアカウントで有効にしたものが同期される。同じ名前のスキルがあると`/anthropic-skills:名前`で呼ぶ。プラグインは`@synced`という配布元で入る |
| Claude Codeに最初から入っているスキル | 本体 | Claude Code | `/loop`、`/code-review`、`/simplify`など |
| Codexに最初から入っているスキルとプラグイン | `~/.codex/skills/.system/`など | Codex | imagegen、documents、browserなど。`ai-doctor`は「宣言にない」とは言わない |
| Codexに登録されたMCPサーバー | Codexの`config.toml` | Codex | ChatGPTアプリが登録したもの（OpenAIの開発者ドキュメントなど） |

- **Claude Desktopアプリ（Cowork）**
  - `~/.claude/skills/`も、リンクになっている`CLAUDE.md`も読まない
  - claude.aiのアカウントで有効にしたスキルだけが使える
  - そのため、このdotfilesで入れたスキルと共通の指示は、Coworkには届かない

## 7. 注意点

- **同じ役割のスキルが複数ある**
  - 例：mattpocock-skillsの`tdd`とSuperpowersの`test-driven-development`
  - 例：`docx`などは、dotfilesで入れたもの、claude.aiから同期されたもの、Codexに最初から入っているものがある
  - どれが使われるかは、そのときの依頼と説明文の合い具合で決まる。気になったら片方を外す
- **Superpowersは返答の進め方を変える**
  - `using-superpowers`が、会話を始めるたびにスキルを使うよう強く促す
  - 合わなければ`ai/plugins.txt`から外し、プラグインもアンインストールする
- **Codexの`openai-curated-remote`にあるプラグインは、ChatGPTにログインしていないアカウントには入れられない**
  - 同じものが`claude-plugins-official`にあれば、そちらを`ai/plugins.txt`に書く
- **`~/.agents/skills/`は、他のツールもスキルを置く場所**
  - 以前はCursorのスキルが20個あり、Codexにも見えていた（Cursorを使わなくなったので削除した）
  - `ai-doctor`は、宣言していないスキルがあると「他のツールが置いたスキル」として表示する
- **find-skillsは、見つけたスキルを`npx skills add`で直接入れようとする**
  - そのまま入れると、このdotfilesの宣言に残らない
  - 使い続けるなら、`ai/skills.txt`に書いて`./ai/install.sh`で入れる
