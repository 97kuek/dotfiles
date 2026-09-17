# dotfilesの仕組み

- このドキュメントでは、このdotfilesが**何を・どこに・どうやって**置いているのかを説明する
- 使い方だけを知りたいときは[README](../README.md)を読む
- Claude CodeとCodexの部分は[ai.md](ai.md)で説明する

## 1. 全体像

### 1.1 考え方

- 「欲しい状態」をこのリポジトリに書いておき、`install.sh`がMacをその状態に揃える
- 扱うものは3種類ある

| 種類 | 例 | 書いてある場所 | 揃える方法 |
| --- | --- | --- | --- |
| 設定ファイル | `.zshrc`、`.gitconfig`、VS Codeの`settings.json` | `zsh/`、`git/`、`vscode/`など | GNU Stowで`~`にリンクする |
| ツールとアプリ | starship、Ghostty、Codex、VS Codeの拡張機能 | `Brewfile` | Homebrewで入れる |
| AIコーディングエージェント | 共通の指示、スキル | `ai/` | `ai/install.sh`がリンクやコマンドで入れる |

- `install.sh`は何度実行しても同じ結果になる
  - 入っているものは飛ばし、足りないものだけを入れる
  - 既存のファイルは上書きせず、一覧を出して止まる

### 1.2 フォルダ構成

```
dotfiles/
├── install.sh          ← セットアップの入口
├── Brewfile            ← Homebrewで入れるツール、アプリ、VS Codeの拡張機能
├── README.md           ← 使い方
├── LICENSE             ← MIT
├── docs/               ← このドキュメントなど
├── .github/workflows/  ← pushしたときにシェルスクリプトをshellcheckで確かめる
├── .shellcheckrc       ← shellcheckの設定
│
├── zsh/                ┐
├── git/                │
├── starship/           │  設定ファイル
├── ghostty/            │  （Stowのパッケージ。中身がそのまま ~ にリンクされる）
├── ssh/                │
├── vscode/             ┘
│
└── ai/                 ← Claude CodeとCodex（詳しくは ai.md）
```

## 2. `install.sh`の流れ

1. **Homebrew**
   - `brew bundle`で`Brewfile`の中身を入れる
   - Claude Codeが入っていなければ、公式のインストーラーで入れる
2. **Gitの外に置く設定の場所を作る**
   - `~/.config/zsh/local/`、`~/.gitconfig.local`、`~/.ssh/config.d/`
3. **競合の確認**
   - `stow --simulate`で、リンクを作らずに試す
   - 既存のファイルとぶつかったら、一覧を出して止まる
4. **リンク**
   - `stow --restow`で、設定ファイルを`~`にリンクする
5. **AI**
   - `ai/install.sh`を呼び、Claude CodeとCodexの指示、設定、プラグイン、スキルを入れる
   - この部分だけをやり直したいときは、`./ai/install.sh`を単独で実行できる

## 3. 設定ファイル：GNU Stow

### 3.1 困っていたこと

- zshやgitは、決まった場所にある設定ファイルを読む
  - zsh → `~/.zshrc`
  - git → `~/.gitconfig`
  - Starship → `~/.config/starship.toml`
- この場所はホームディレクトリのあちこちに散らばっている
- そのままでは、まとめてGitで管理できない

### 3.2 解決策：本体はdotfilesに置き、決まった場所にはリンクを置く

- シンボリックリンクは、Windowsのショートカットのようなもの
- `~/.zshrc`を開くと、実際には`~/dotfiles/zsh/.zshrc`の中身が読まれる

```
~/.zshrc  ──(リンク)──▶  ~/dotfiles/zsh/.zshrc   ← 本体（Gitで管理）
```

- dotfiles側を編集すると、そのまま反映される
- 変更はそのままGitでコミットできる

### 3.3 Stowのルール

- Stowは、フォルダの構造を見てリンクをまとめて作る道具
- ルールは1つだけ
  - **先頭のフォルダ名（パッケージ名）を取り除いたパスに、リンクを置く**

```
dotfiles/zsh/.zshrc                      →  ~/.zshrc
dotfiles/git/.gitconfig                  →  ~/.gitconfig
dotfiles/starship/.config/starship.toml  →  ~/.config/starship.toml
```

- dotfilesの中に`.config/`のような深いフォルダがあるのは、リンク先の場所を再現するため
- フォルダごとリンクされることもある
  - リンク先にフォルダがまだないとき、Stowはファイルごとではなくフォルダごとリンクする
  - たとえば`~/.config/zsh`は、`dotfiles/zsh/.config/zsh`へのリンクになっている
  - そのため`~/.config/zsh/local/`に置いたファイルの実体は、`dotfiles/zsh/.config/zsh/local/`にできる
  - この中は`.gitignore`で除外しているので、コミットされることはない

### 3.4 パッケージの一覧

| パッケージ | リポジトリのファイル | `~`でのパス |
| --- | --- | --- |
| zsh | `zsh/.zprofile` | `~/.zprofile` |
| | `zsh/.zshrc` | `~/.zshrc` |
| | `zsh/.config/zsh/` | `~/.config/zsh/` |
| git | `git/.gitconfig` | `~/.gitconfig` |
| | `git/.config/git/ignore` | `~/.config/git/ignore` |
| starship | `starship/.config/starship.toml` | `~/.config/starship.toml` |
| ghostty | `ghostty/.config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` |
| ssh | `ssh/.ssh/config` | `~/.ssh/config` |
| vscode | `vscode/Library/Application Support/Code/User/settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| | `vscode/Library/Application Support/Code/User/keybindings.json` | `~/Library/Application Support/Code/User/keybindings.json` |

## 4. ツールとアプリ：Homebrew

- 設定ファイルがあっても、Starshipやzshのプラグインの本体が入っていなければ動かない
- `Brewfile`は「このMacに入れたいもののリスト」

```ruby
brew "starship"   # CLIツール
cask "ghostty"    # GUIアプリ
```

- `brew bundle`を実行すると、このリストのうち、まだ入っていないものだけが入る
- 入れているもの

| 種類 | 中身 |
| --- | --- |
| 言語とパッケージ管理 | go、node、volta、pyenv、uv、poetry、cocoapods |
| ビルドと開発ツール | cmake、ninja、llvm、gh、jq、shellcheck、stow、tmux、wget |
| そのほかのCLI | azure-cli、gcloud-cli、libpq、ffmpeg、plantuml、ollama |
| シェル | starship、zsh-autosuggestions、zsh-syntax-highlighting |
| AI | Codex、Claude、ChatGPT、CodexBar |
| アプリ | Ghostty、VS Code、Android Studio、Flutter、MacTeX、Docker、Chrome、Slack、Zoom、Raycast、draw.io、AppCleaner、Aqua Voice、Capsomnia、Logi Options+ |
| VS Codeの拡張機能 | 使っているもの全部（`vscode "…"`の行） |

- 入れていないもの
  - **zsh**：macOS標準の`/bin/zsh`を使う。Homebrewで入れても使われない2つ目のzshが増えるだけ
  - **Claude Code**：Homebrewで入れると自動で更新されないので、公式のインストーラーで入れる
  - **組織の端末管理（MDM）が入れたアプリ**：Company Portal、Microsoft Defender、Teams。二重に管理すると衝突する
  - **App Storeから入れたアプリ**：Office、Bitwarden、LINE、Kindle、Xcodeなど。Apple IDでのログインが前提になる
- 手で入れたアプリをHomebrewの管理に移すときは、`brew install --cask --adopt <名前>`を使う
  - アプリを入れ直さずに、Homebrewの管理に移せる。管理者のパスワードを聞かれる
- VS Codeの拡張機能を増やしたときは、`code --list-extensions`の結果に合わせて`Brewfile`に`vscode "…"`を足す

## 5. 各設定の中身

### 5.1 zsh

- 読み込まれる順番

```
.zprofile（ログインシェルのときだけ）
  └ Homebrewにパスを通す

.zshrc
  ├ ~/.local/bin をPATHに追加          … Claude Codeなど
  ├ SDKROOT を設定                     … clangdやclang-tidyがmacOSのSDKを見つけられるようにする
  └ config.zsh
       ├ LANG、EDITOR                   … nvimがあればnvim、なければvim
       ├ pyenv                          … Pythonのバージョン切り替え（入っているときだけ。下で説明）
       ├ Volta                          … Nodeのバージョン切り替え（入っているときだけ）
       ├ Starship                       … プロンプト
       ├ autosuggestions、syntax-highlighting
       ├ ↑↓キー                         … 入力途中の文字から始まる履歴だけをたどる
       ├ WORDCHARS=''                   … 単語削除を / などの記号で止める
       ├ interactivecomments            … 対話中のコマンドでも # 以降をコメントとして扱う
       ├ local/*.zsh                    … 秘密情報や端末固有の設定（Gitの外）
       └ ai.zsh                         … AIのアカウント切り替え（ai.mdで説明）
```

- pyenvは遅く読み込む
  - `pyenv init`はzshの起動時間の大半（約0.09秒）を占めていた
  - 起動時はPATHにpyenvのshimsだけを足す。これだけで`python`は`.python-version`に従う
  - `pyenv`コマンドを初めて使ったときに、`pyenv init`を実行する
  - その結果、zshの起動は約0.12秒から約0.03秒になった
- `local/*.zsh`を`ai.zsh`より先に読むのは、`ai.zsh`の設定を端末ごとに上書きできるようにするため
- ツールのインストーラーが`.zshrc`の末尾に設定を書き足すことがある
  - そのときは`config.zsh`に移し、`command -v`で入っているか確かめてから読むようにする
  - こうしておくと、そのツールがないMacでもエラーにならない

### 5.2 Git

- `.gitconfig`は、最初に`~/.gitconfig.local`を読み込む
  - 名前とメールアドレスはそこに書き、リポジトリには入れない
- 主な設定

| 設定 | 効果 |
| --- | --- |
| `pull.ff = only` | pullで勝手にマージコミットを作らない |
| `fetch.prune = true` | リモートで消えたブランチを、手元の一覧からも消す |
| `push.autoSetupRemote = true` | 初回のpushで、上流ブランチを自動で設定する |
| `rebase.autoStash = true` | rebaseの前後で、作業中の変更を自動で退避・復元する |
| `diff.algorithm = histogram`、`diff.colorMoved = zebra` | 差分を読みやすくする |
| `branch.sort = -committerdate` | ブランチの一覧を、更新日時の新しい順に並べる |

- `.config/git/ignore`は、すべてのリポジトリで無視するファイル
  - `.DS_Store`、vimの一時ファイル、`.claude/settings.local.json`など

### 5.3 SSH

- `config`は、最初に`Include ~/.ssh/config.d/*.conf`を読む
  - sshは、同じ設定項目については最初に読んだ値を使う
  - 公開したくないホストや、端末ごとの上書きを先に読ませるため
- `IdentityFile`（使う鍵）は`Host *`に書かず、`github.com`などホストごとに指定する
  - `Host *`に書くと、すべてのホストに同じ鍵を渡してしまう
- `.gitignore`で`ssh/.ssh/`の中は`config`以外を除外している
  - 誤って鍵を置いても、コミットされない

### 5.4 Starship

- 配色はGruvbox Darkで、区切りに矢印の記号を使う
- 左から順に表示するもの
  - OSとユーザー名 → ディレクトリ → Gitのブランチと状態 → 言語のバージョン → docker/conda/AIのアカウント → 時刻
- `ai-use`でアカウントを切り替えると、そのアカウント名がプロンプトに出る

### 5.5 Ghostty

- フォントサイズ18、テーマはTomorrow Night、ウィンドウの状態を保存する
- このリポジトリで追加したキー

| 操作 | キー |
| --- | --- |
| 右に分割 / 下に分割 | `Ctrl+Shift+V` / `Ctrl+Shift+H` |
| 分割間を移動 | `Ctrl+H` / `Ctrl+J` / `Ctrl+K` / `Ctrl+L`（左/下/上/右） |
| 分割を閉じる | `Ctrl+X` |
| 分割のサイズ変更 | `Ctrl+,` / `Ctrl+.` / `Ctrl+;` / `Ctrl+'`（左/右/下/上に10） |
| スクロール | `Ctrl+Shift+K` / `Ctrl+Shift+J`（上/下に3行） |
| 改行を入力 | `Shift+Enter`（Claude Codeなどで複数行を書くため） |
| 単語単位で削除 | `Alt+Backspace` / `Shift+Backspace` |

- Ghostty標準のキーもそのまま使える

| 操作 | キー |
| --- | --- |
| 右に分割 / 下に分割 | `⌘D` / `⌘⇧D` |
| 次 / 前の分割へ | `⌘]` / `⌘[` |
| 方向で分割間を移動 | `⌘⌥` + 矢印 |
| 分割のサイズ変更 / 均等にする | `⌘⌃` + 矢印 / `⌘⌃=` |
| 分割を閉じる | `⌘W` |
| 新しいタブ / ウィンドウ | `⌘T` / `⌘N` |
| 設定を読み直す | `⌘⇧,` |

- 注意：`Ctrl+H`、`Ctrl+J`、`Ctrl+K`、`Ctrl+L`、`Ctrl+X`はGhosttyが受け取るので、シェルには届かない
  - `Ctrl+L`の画面クリア、`Ctrl+K`の行削除などは効かない
  - `keybind = performable:ctrl+l=goto_split:right`のように`performable:`を付けると、移動先の分割があるときだけGhosttyが受け取り、ないときはシェルに渡すようになる

### 5.6 VS Code

- `settings.json`と`keybindings.json`を管理する
  - LaTeX Workshop（LuaLaTeXでビルド）、日本語の文字を警告しない設定、ターミナルの設定など
  - ターミナルで`Shift+Enter`を押すと改行を送る（Claude Codeで複数行を書くため）
- 拡張機能は`Brewfile`の`vscode "…"`で入れる
- VS Codeが設定を保存するときにリンクを実体のファイルで置き換えた場合は、`./install.sh`の競合の確認で止まる
  - そのときは、実体のファイルの変更をdotfiles側に写してから、実体を退避して再実行する

## 6. Gitに入れないもの

- 秘密情報と端末固有の設定は、リポジトリの外に置いて自動で読み込む

| 場所 | 用途 |
| --- | --- |
| `~/.config/zsh/local/*.zsh` | APIトークン、会社固有のalias、端末固有の環境変数 |
| `~/.gitconfig.local` | Gitの名前とメールアドレス |
| `~/.ssh/config.d/*.conf` | 公開したくないSSHホスト |
| `~/.ssh/id_*` | SSHの鍵 |
| `~/.claude`、`~/.codex`、`~/.ai/` | AIのログイン情報、履歴、プラグインの実体 |
| `~/.local/share/dotfiles/skill-repos/` | `ai/skills.txt`で取得したスキルの実体 |
| 各リポジトリの`.claude/settings.local.json` | プロジェクト専用の、Claude Codeの許可のルール |

- このリポジトリは公開されている
  - 会社のアカウントで作ったスキル（採用基準や議事録のフォーマットなど）も入れない

## 7. シェルスクリプトのチェック

- `install.sh`と`ai/*.sh`は、shellcheckで書き方の誤りを確かめる
  - 手元：`shellcheck install.sh ai/*.sh`
  - GitHub：pushすると、GitHub Actions（`.github/workflows/shellcheck.yml`）が同じチェックを実行する
- 設定は`.shellcheckrc`にある
  - `sh`として確かめる、`ai/lib.sh`の読み込みもたどる
- `ai.zsh`などのzshのファイルは、shellcheckが対応していないので対象外
