# dotfilesの仕組み

- このドキュメントは、このdotfilesが**何を・どこに・どうやって**置いているのかを説明する
- 使い方だけを知りたいときは[README](../README.md)を読む
- 入れているスキルの一覧は[skills.md](skills.md)にまとめている

## 1. 目的

- 新しいMacでも`./install.sh`を1回実行するだけで、今と同じ開発環境に戻せるようにする
- そのために、次の3種類を扱う
  - **設定ファイル**：zsh、git、ssh、Starship、Ghostty
  - **アプリとツール**：Homebrewで入れるもの
  - **AIコーディングエージェント**：Claude CodeとCodexの本体、共通の指示、設定、プラグイン、スキル、アカウント
- 3種類とも「欲しい状態をリポジトリに書いておき、`install.sh`がその状態に揃える」という考え方で作っている
- `install.sh`は何度実行しても同じ結果になる
  - 入っているものは飛ばし、足りないものだけを入れる
  - 設定を変えたあとの再適用にもそのまま使える

## 2. 全体像

```
dotfiles/
├── install.sh              ← セットアップの入口
├── Brewfile                ← Homebrewで入れるツールとアプリ
├── README.md               ← 使い方
├── docs/
│   ├── how-it-works.md     ← このファイル（仕組み）
│   └── skills.md           ← 入れているスキルの一覧
│
├── zsh/                    ┐
├── git/                    │  設定ファイル（Stowのパッケージ）
├── starship/               │  中身をそのまま ~ にリンクする
├── ghostty/                │
├── ssh/                    ┘
│
└── ai/                     ← Claude CodeとCodex（Stowは使わない）
    ├── install.sh          ← 指示・設定・プラグイン・スキルを導入する
    ├── update.sh           ← まとめて更新する（ai-update）
    ├── doctor.sh           ← 宣言どおりか確かめる（ai-doctor）
    ├── lib.sh              ← 上の3つが共通で使う関数
    ├── AGENTS.md           ← ClaudeとCodexへの共通の指示
    ├── claude/
    │   └── settings.json   ← Claude Codeの設定
    ├── marketplaces.txt    ← プラグインの配布元
    ├── plugins.txt         ← 入れるプラグイン
    ├── skills.txt          ← 入れるスキル（GitHubから取得）
    └── skills/             ← 自作スキル
```

## 3. セットアップの流れ

- `install.sh`は次の5つを順番に行う
  1. **Homebrew**：`brew bundle`で`Brewfile`の中身を入れる。Claude Codeが入っていなければ公式のインストーラーで入れる
  2. **ローカル設定の置き場所を作る**：`~/.config/zsh/local/`、`~/.gitconfig.local`、`~/.ssh/config.d/`
  3. **競合の確認**：`stow --simulate`で試し、既存のファイルとぶつかったら一覧を出して止まる
  4. **リンク**：`stow --restow`で設定ファイルを`~`にリンクする
  5. **AI**：`ai/install.sh`を呼び、Claude CodeとCodexの共通の指示、設定、プラグイン、スキルを入れる
- 5だけをやり直したいときは`./ai/install.sh`を単独で実行できる
  - Homebrewを待たずに、AIまわりの変更だけを反映できる

## 4. 設定ファイル：GNU Stow

### 4.1 解決したい問題

- zshやgitは、決まった場所にある設定ファイルを読む
  - zsh → `~/.zshrc`
  - git → `~/.gitconfig`
  - Starship → `~/.config/starship.toml`
- この場所はホームディレクトリのあちこちに散らばっている
- そのままでは、まとめてGitで管理できない

### 4.2 解決策：本体はdotfilesに置き、決まった場所にはリンクを置く

- シンボリックリンクは、Windowsのショートカットのようなもの
- `~/.zshrc`を開くと、実際には`~/dotfiles/zsh/.zshrc`の中身が読まれる

```
~/.zshrc  ──(リンク)──▶  ~/dotfiles/zsh/.zshrc   ← 本体（Gitで管理）
```

- dotfiles側を編集すると、すぐにzshにも反映される
- 変更はそのままGitでコミットできる

### 4.3 Stowはリンクを自動で作る道具

- 手作業なら、ファイルの数だけ`ln -s`を打つことになる
- Stowはフォルダの構造を見て、リンクをまとめて作る
- ルールは1つだけ
  - **先頭のフォルダ名（パッケージ名）を取り除いたパスに、リンクを置く**

```
dotfiles/zsh/.zshrc                      →  ~/.zshrc
dotfiles/git/.gitconfig                  →  ~/.gitconfig
dotfiles/starship/.config/starship.toml  →  ~/.config/starship.toml
```

- dotfilesの中に`.config/`のような深いフォルダがあるのは、リンク先の場所を再現するため
- `~/.config/zsh`や`~/.config/ghostty`のように、フォルダごとリンクされることもある
  - リンク先にフォルダがまだないとき、Stowはファイルごとではなくフォルダごとリンクする
  - そのため`~/.config/zsh/local/`に置いたファイルの実体は、`dotfiles/zsh/.config/zsh/local/`にできる
  - この中は`.gitignore`で除外しているので、コミットされることはない

### 4.4 パッケージの一覧

- `zsh`
  - `zsh/.zprofile` → `~/.zprofile`
  - `zsh/.zshrc` → `~/.zshrc`
  - `zsh/.config/zsh/` → `~/.config/zsh/`
- `git`
  - `git/.gitconfig` → `~/.gitconfig`
  - `git/.config/git/ignore` → `~/.config/git/ignore`
- `starship`
  - `starship/.config/starship.toml` → `~/.config/starship.toml`
- `ghostty`
  - `ghostty/.config/ghostty/config.ghostty` → `~/.config/ghostty/config.ghostty`
- `ssh`
  - `ssh/.ssh/config` → `~/.ssh/config`

## 5. アプリとツール：Homebrew

- 設定ファイルがあっても、zshのプラグインやStarship、Ghosttyの本体が入っていなければ動かない
- `Brewfile`は「このMacに入れたいもののリスト」になっている

```ruby
brew "starship"   # CLIツール
cask "ghostty"    # GUIアプリ
```

- `brew bundle`を実行すると、このリストのうちまだ入っていないものだけが入る
- 入れているもの
  - **CLIツール**：gh、node、pyenv、starship、stow、tmux、uv、volta、cocoapods
  - **zshのプラグイン**：zsh-autosuggestions、zsh-syntax-highlighting
  - **AIのCLI**：Codex（`cask "codex"`）
  - **GUIアプリ**：Ghostty、Android Studio、Flutter、MacTeX、CodexBar
- zshはHomebrewで入れない
  - ログインシェルはmacOS標準の`/bin/zsh`で、プラグインもそれで動く
  - 入れても使われない2つ目のzshが増えるだけになる

## 6. 各設定の中身

### 6.1 zsh

- 読み込まれる順番

```
.zprofile（ログインシェルのときだけ）
  └ brew shellenv            … Homebrewにパスを通す

.zshrc
  ├ ~/.local/bin をPATHに追加
  ├ SDKROOT を設定            … clangdやclang-tidyがmacOSのSDKを見つけられるようにする
  └ config.zsh
       ├ LANG、EDITOR（nvimがあればnvim、なければvim）
       ├ pyenv                … Pythonのバージョン切り替え（入っているときだけ）
       ├ Volta                … Nodeのバージョン切り替え（入っているときだけ）
       ├ Starship             … プロンプト
       ├ autosuggestions、syntax-highlighting
       ├ ↑↓キー               … 入力途中の文字から始まる履歴だけをたどる
       ├ WORDCHARS=''         … 単語削除を / などの記号で止める
       ├ interactivecomments  … 対話中のコマンドでも # 以降をコメントとして扱う
       ├ local/*.zsh          … 秘密情報や端末固有の設定（Git管理外）
       └ ai.zsh               … AIのアカウント切り替え（7.2で説明）
```

- `local/*.zsh`を`ai.zsh`より先に読むのは、`ai.zsh`の設定を端末ごとに上書きできるようにするため
- ツールが`.zshrc`の末尾に設定を自動で書き足すことがある
  - そのときは`config.zsh`に移し、`command -v`で入っているか確かめてから読むようにする
  - 入っていないMacでもエラーにならない

### 6.2 git

- `.gitconfig`は、最初に`~/.gitconfig.local`を読み込む
  - 名前とメールアドレスはそこに書き、リポジトリには入れない
- 主な設定
  - `pull.ff = only`：pullで勝手にマージコミットを作らない
  - `fetch.prune = true`：リモートで消えたブランチを手元からも消す
  - `push.autoSetupRemote = true`：初回のpushで上流ブランチを自動で設定する
  - `rebase.autoStash = true`：rebaseの前後で作業中の変更を自動で退避・復元する
  - `diff.algorithm = histogram`、`diff.colorMoved = zebra`：差分を読みやすくする
  - `branch.sort = -committerdate`：ブランチの一覧を更新日時の新しい順に並べる
- `.config/git/ignore`は、すべてのリポジトリで無視するファイル
  - `.DS_Store`、vimの一時ファイル、`.claude/settings.local.json`など

### 6.3 ssh

- `config`は、最初に`Include ~/.ssh/config.d/*.conf`を読む
  - sshは同じ設定項目について最初に読んだ値を使う
  - 公開したくないホストや、端末ごとの上書きを先に読ませるため
- `IdentityFile`は`Host *`に書かず、`github.com`などホストごとに指定する
  - `Host *`に書くと、すべてのホストに同じ鍵を渡してしまう
- `.gitignore`で`ssh/.ssh/`の中は`config`以外を除外している
  - 鍵を置いても誤ってコミットされない

### 6.4 Starship

- 配色はGruvbox Darkで、区切りに矢印の記号を使う
- 左から順に表示するもの
  - OSとユーザー名 → ディレクトリ → gitのブランチと状態 → 言語のバージョン → docker/conda/AIのアカウント → 時刻
- `ai-use`でアカウントを切り替えると、そのアカウント名がプロンプトに出る

### 6.5 Ghostty

- フォントサイズ18、テーマはTomorrow Night、ウィンドウの状態を保存する
- 分割をvim風のキーで操作する
- `Shift+Enter`で改行を入力できる（Claude Codeなどで複数行を書くため）
- キーの一覧はREADMEにある

## 7. AIコーディングエージェント：Claude CodeとCodex

### 7.1 Stowで管理しない理由

- `~/.claude`や`~/.codex`には、設定と一緒に次のものも書き込まれる
  - 会話の履歴、セッション、ログ
  - ログインの情報
- フォルダごとGitで管理すると、差分のほとんどが履歴になり、ログインの情報まで入ってしまう
- そこで、**入れたいものを宣言しておき、`ai/install.sh`がCLIのコマンドやリンクで入れる**
  - リポジトリに置くのは「何を入れるか」と、自分で書いたもの（共通の指示、設定、自作スキル）だけ
  - 外部のスキルの中身は置かない。コピーすると配布元の更新を追えなくなるため

### 7.2 本体のインストール

- **Claude Code**
  - 公式のインストーラー（`curl -fsSL https://claude.ai/install.sh | bash`）で`~/.local/bin/claude`に入れる
  - この方法だと自動で更新される。Homebrewで入れると自動で更新されない
  - `install.sh`は、`claude`が見つからないときだけインストーラーを実行する
- **Codex**
  - `Brewfile`の`cask "codex"`で入れる
  - `npm i -g`で入れるのはやめた。Voltaを入れたので、npmのグローバルな場所がHomebrewのnodeとVoltaの2か所に分かれてしまうため
- どちらも`ai-update`でまとめて更新できる（7.11）

### 7.3 アカウントの切り替え

- Claude Codeは`CLAUDE_CONFIG_DIR`、Codexは`CODEX_HOME`で設定フォルダの場所を決める
- この値を差し替えると、ログイン情報ごと別のアカウントになる
- `zsh/.config/zsh/ai.zsh`がこれを使って、アカウントを切り替えられるようにしている
  - 既定のアカウント（`personal`）は、今までどおり`~/.claude`と`~/.codex`を使う
  - それ以外のアカウントは`~/.ai/<名前>/claude`と`~/.ai/<名前>/codex`に置く
  - `~/.ai/`の下のフォルダを見つけて、`claude-<名前>`や`codex-<名前>`というコマンドを自動で作る
- コマンド
  - `ai-new <名前>`：アカウントを作る。そのあと`./ai/install.sh`で指示・設定・プラグイン・スキルを入れる
  - `claude-<名前>`、`codex-<名前>`：そのアカウントで起動する（初回はログインする）
  - `ai <名前> [コマンド]`：そのアカウントで1回だけ実行する。今のシェルは切り替わらない
  - `ai-use <名前>`：今のシェル全体を切り替える
  - `ai-ls`：アカウントと、それぞれの保存先の一覧
- アカウントを消すときは`~/.ai/<名前>`を削除して、シェルを開き直す

### 7.4 共通の指示：`ai/AGENTS.md`

- Claude CodeとCodexには、すべてのプロジェクトで最初に読む指示ファイルがある
  - Claude Code：`<設定フォルダ>/CLAUDE.md`
  - Codex：`<設定フォルダ>/AGENTS.md`
- 書式はどちらもただのMarkdownなので、1つのファイルを両方にリンクする
  - 実体は`ai/AGENTS.md`だけ。ここを直せば、両方のCLIの全アカウントに反映される
- 書いていること
  - 日本語で答える、決めるべきことは聞く
  - 環境（macOS、zsh、Homebrew、uv、pyenv、Volta）
  - 設定ファイルはdotfiles側を編集する
  - コミットとpushは頼まれたときだけ、秘密情報を出さない
- 書かないこと
  - プロジェクトごとの指示。各リポジトリの`CLAUDE.md`や`AGENTS.md`に書く
  - 長い説明。毎回のセッションで読み込まれるので、短く保つ
- Claude DesktopアプリのCoworkは、リンクになっている`CLAUDE.md`を読まない

### 7.5 Claude Codeの設定：`ai/claude/settings.json`

- `~/.claude/settings.json`は、全アカウントでこのファイルへのリンクになる
- 入れている設定
  - 見た目：モデル、テーマ、全画面表示、通知
  - 有効にするプラグインと、その配布元
  - 許可のルール（`permissions`）
- 許可のルールは3種類ある。評価は deny → ask → allow の順で、先に当たったものが使われる
  - **allow**：確認せずに実行する
    - どのプロジェクトでも使う、安全なコマンドだけを置く（git、gh、uv、pytest、ruffなど）
    - `~/`以下の読み取りは許可する
  - **ask**：allowに当たっても、必ず確認する
    - `git push --force`、`git reset --hard`、`git clean`、`sudo`
  - **deny**：実行させない
    - 秘密情報の読み取り：SSHの鍵、`~/.config/zsh/local/*.zsh`、`.env`、Codex・gh・gcloud・AWS・Docker・npmの認証情報
    - denyはClaudeのファイル操作と、`cat`などの分かりやすいコマンドには効く。PythonやNodeのスクリプトが中で開くファイルまでは防げない
- 入れないもの
  - プロジェクト専用のコマンド（`make eval`、特定のスクリプトなど）。各リポジトリの`.claude/settings.local.json`に置く
  - 一度きりのコマンド。確認のときに「今回だけ許可」を選ぶ
- Claude Codeは、このファイルを自分で書き換えることがある
  - プラグインの有効化、`/config`での変更、「次回から聞かない」を選んだときなど
  - リンクなので、その変更はdotfilesの差分に出る。`git diff`で見て、残すか戻すかを決める
- 移行前の設定は`~/.claude/settings.json.before-dotfiles`に残している

### 7.6 スキルとプラグインの違い

- **スキル**
  - `SKILL.md`を1つ含むフォルダ
  - 「いつ使うか」の説明と、「どう進めるか」の手順が書いてある
  - 書式はClaude CodeとCodexで共通になっている
- **プラグイン**
  - 複数のスキルや、フック、コマンド、LSPなどをまとめて配るための入れ物
  - マーケットプレイス（配布元）から、CLIのコマンドで入れる

### 7.7 Claude CodeとCodexでは、スキルを読む場所が違う

- 自分用のスキルを読む場所

| | 読む場所 | アカウントを切り替えると |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | 公式ドキュメントに明記がないため、各アカウントの`skills/`にもリンクする |
| Codex | `~/.agents/skills/` | `CODEX_HOME`に関係なく、同じ場所を読む |

- プラグインが入る場所

| | 入る場所 | アカウントを切り替えると |
| --- | --- | --- |
| Claude Code | `<設定フォルダ>/plugins/` | アカウントごとに別になる |
| Codex | `<設定フォルダ>/plugins/` | アカウントごとに別になる |

- つまり、何もしなければ次のようになる
  - スキルは、ClaudeとCodexで別々に置く必要がある
  - プラグインは、CLIごと・アカウントごとに入れる必要がある

### 7.8 設計：スキルは1か所に集め、そこから配る

- **スキル**は`~/.agents/skills/`を共通の置き場所にする
  - Codexはここを直接読む
  - Claude Codeには、ここから`~/.claude/skills/`へもう一段リンクする
  - どちらのCLIも、どのアカウントでも、同じ実体を読むことになる

```
【スキル】
ai/skills.txt ─(git clone)─▶ ~/.local/share/dotfiles/skill-repos/<owner>/<repo>/
                                        │
ai/skills/<名前>/ ──────────────────────┤
                                        ▼
                             ~/.agents/skills/<名前>   ← 共通の置き場所
                                        │
                      ┌─────────────────┼────────────────────────┐
                      ▼                 ▼                        ▼
                    Codex      ~/.claude/skills/<名前>   ~/.ai/<アカウント>/claude/skills/<名前>
                 （直接読む）     （Claude Code）            （Claude Code・別アカウント）

【プラグイン】
ai/plugins.txt ─(claude plugin install / codex plugin add)─▶ 各CLI × 各アカウントの plugins/

【共通の指示と設定】
ai/AGENTS.md ─────────────▶ 各アカウントの CLAUDE.md（Claude Code）、AGENTS.md（Codex）
ai/claude/settings.json ──▶ 各アカウントの settings.json（Claude Code）
```

- **プラグイン**は、`ai/install.sh`がCLIごと・アカウントごとに同じものを入れる
  - `ai/plugins.txt`の2列目で、ClaudeだけやCodexだけに絞れる
  - Codexは`claude-plugins-official`などClaude向けの配布元からもプラグインを入れられる
  - そのためSuperpowersは、両方のCLIに同じ配布元から入れている

### 7.9 どこに書くかの決め方

- 配布元が**複数のスキルやフックをまとめたプラグイン**として配っている → `ai/plugins.txt`
  - 例：mattpocock-skills、Superpowers、codex、clangd-lsp
  - フックやコマンドはスキルの置き場所では動かないため、プラグインとして入れる
- **1つのスキルだけ**が欲しい → `ai/skills.txt`
  - 例：Anthropicのdocx、pptx、xlsx、pdf、frontend-design、doc-coauthoring
  - 例：Vercelのweb-design-guidelines、find-skills
  - プラグインで入れると、欲しくないスキルまで一緒に入ってしまうことがあるため
- **自分で書いた**スキル → `ai/skills/<名前>/`
  - 書き方は`ai/skills/README.md`にある
- **すべてのプロジェクトで守ってほしいこと** → `ai/AGENTS.md`
- **Claude Codeの許可や見た目** → `ai/claude/settings.json`

### 7.10 `ai/install.sh`がやること

1. **プラグイン**
   - `~/.claude`と`~/.ai/*/claude`のそれぞれで、`marketplaces.txt`の配布元を登録する
   - 同じく`plugins.txt`のプラグインのうち、入っていないものを入れる
   - Codexも`~/.codex`と`~/.ai/*/codex`で同じことをする
2. **スキルを集める**
   - `skills.txt`のリポジトリを`~/.local/share/dotfiles/skill-repos/`に取得する。取得済みなら最新にする
   - 各スキルと`ai/skills/`の自作スキルを、`~/.agents/skills/<名前>`にリンクする
   - `skills.txt`から消したスキルのリンクは片付ける
3. **Claude Codeへ配る**
   - 宣言したスキルだけを、`~/.claude/skills/`と`~/.ai/*/claude/skills/`にリンクする
   - 宣言から消したスキルのリンクは片付ける
4. **共通の指示と設定をリンクする**
   - `ai/AGENTS.md`を、各アカウントの`CLAUDE.md`と`AGENTS.md`にリンクする
   - `ai/claude/settings.json`を、各アカウントの`settings.json`にリンクする

- 消すのは自分が作ったリンクだけ
  - 他のツールが置いたスキルや、同じ名前の実体があるときは、上書きせずに警告を出す
  - 実体のファイルがあるときは、退避してから再実行する（例：`mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.before-dotfiles`）

### 7.11 `ai-update`と`ai-doctor`

- `ai-update`：まとめて最新にする
  1. 本体：`claude update`と`brew upgrade --cask codex`
  2. プラグイン：Claude Codeは全アカウントで配布元を更新してから、入っているプラグインを1つずつ更新する。Codexは全アカウントで配布元を更新する
  3. スキル：`ai/install.sh`を実行し、`skills.txt`のリポジトリを取得し直して宣言に揃える
  - 起動中のセッションには、再起動すると反映される
- `ai-doctor`：宣言どおりになっているかを確かめる
  - 本体：`claude`と`codex`が入っているか、Codexが`Brewfile`どおりHomebrewから入っているか
  - 共通の指示と設定：全アカウントで`ai/`へのリンクになっているか
  - プラグイン：宣言したものが全アカウントに入っているか、宣言にないものが入っていないか
  - スキル：宣言したものが`~/.agents/skills/`と全アカウントの`skills/`にあるか、壊れたリンクがないか
  - `✗`は問題、`⚠`は注意。問題があれば終了ステータス1で終わる
  - 多くの問題は`./ai/install.sh`で直る
- どちらも実体は`ai/update.sh`と`ai/doctor.sh`で、`ai.zsh`の関数から呼んでいる

### 7.12 dotfilesの外から入ってくるスキル

- dotfilesで管理していなくても、次のスキルは自動で入ってくる
  - **claude.aiのアカウントのスキル**
    - claude.aiで有効にしたスキルが、Claude Codeの`~/.claude/skills/synced/`に同期される
    - ログインしているアカウントのものだけが届く
    - 同じ名前のスキルが`~/.claude/skills/`にあるときは、そちらが`/名前`になる。同期された方は`/anthropic-skills:名前`で呼べる
  - **Claude Codeに最初から入っているスキル**：`/loop`、`/code-review`、`/simplify`など
  - **Codexに最初から入っているスキルとプラグイン**：imagegen、skill-creator、documentsなど
    - `openai-primary-runtime`、`openai-bundled`、`openai-curated-remote`の配布元から自動で入る
    - `ai-doctor`は、これらを「宣言にない」とは言わない
  - **Cursorが置いたスキル**
    - Cursorは`~/.agents/skills/`に自分のスキル（`canvas`、`babysit`など）を置いている
    - Codexも同じ場所を読むので、CodexにはCursor向けのスキルも見えている
    - `ai/install.sh`はこれらをClaude Codeへリンクしない
- **Claude Desktopアプリ（Cowork）**
  - `~/.claude/skills/`を読まない
  - claude.aiのアカウントで有効にしたスキルだけが使える
  - そのため、dotfilesで入れたスキルはCoworkには出てこない

### 7.13 よくある作業

- スキルを追加する
  - `ai/skills.txt`に1行足して`./ai/install.sh`を実行する
  - `docs/skills.md`にも追記する
- スキルを削除する
  - `ai/skills.txt`から行を消して`./ai/install.sh`を実行する。リンクも片付く
- プラグインを追加する
  - `ai/plugins.txt`に1行足して`./ai/install.sh`を実行する
- プラグインを削除する
  - `ai/plugins.txt`から行を消すだけでは消えない
  - `claude plugin uninstall <プラグイン>`や`codex plugin remove <プラグイン>`を、アカウントごとに実行する
  - 消し忘れは`ai-doctor`が「plugins.txt にありません」と教えてくれる
- 全部を最新にする：`ai-update`
- 状態を確かめる：`ai-doctor`
- 共通の指示や許可のルールを変える
  - `ai/AGENTS.md`や`ai/claude/settings.json`を編集してコミットする。リンクなのですぐに反映される

## 8. Gitに入れないもの

- 秘密情報と端末固有の設定は、リポジトリの外に置いて自動で読み込む

| 場所 | 用途 |
| --- | --- |
| `~/.config/zsh/local/*.zsh` | APIトークン、会社固有のalias、端末固有の環境変数 |
| `~/.gitconfig.local` | Gitの名前とメールアドレス |
| `~/.ssh/config.d/*.conf` | 公開したくないSSHホスト |
| `~/.ssh/id_*` | SSHの鍵 |
| `~/.claude`、`~/.codex`、`~/.ai/` | AIのログイン情報、履歴、プラグインの実体 |
| `~/.local/share/dotfiles/skill-repos/` | `skills.txt`で取得したスキルの実体 |
| 各リポジトリの`.claude/settings.local.json` | プロジェクト専用の許可のルール |

- 会社のアカウントで作ったスキル（採用基準や議事録のフォーマットなど）も、このリポジトリには入れない

## 9. 注意点

- 同じ役割のスキルが複数ある
  - 例：mattpocock-skillsの`tdd`とSuperpowersの`test-driven-development`
  - 例：`docx`などは、dotfilesで入れたものとclaude.aiから同期されたものの両方がある
  - どちらが使われるかは、そのときの説明文との一致具合で決まる。気になったら片方を外す
- Superpowersの`using-superpowers`は、会話を始めるたびにスキルを使うよう強く促す
  - 返答の進め方が変わるので、合わなければ`plugins.txt`から外す
- Codexの`openai-curated-remote`にあるプラグインは、ChatGPTにログインしていないアカウントには入れられない
  - 同じものが`claude-plugins-official`にあれば、そちらを`plugins.txt`に書く
- `.env.*`の読み取りを禁止しているので、`.env.example`も読めない
  - 読ませたいときは、そのプロジェクトの`.claude/settings.local.json`で許可する
