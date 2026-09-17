# dotfiles

> macOSの開発環境を、`./install.sh`を1回実行するだけで再現するための設定集

## このリポジトリでできること

- **設定ファイルをまとめて管理する**：zsh、Git、SSH、Starship、Ghostty、VS Codeの設定を`~`にリンクする
- **ツールとアプリを入れる**：`Brewfile`に書いたCLI、アプリ、VS Codeの拡張機能をHomebrewでまとめて入れる
- **AIコーディングエージェントを揃える**：Claude CodeとCodexの本体、共通の指示、設定、プラグイン、MCPサーバー、スキルを入れる
- **何度実行しても安全**：入っているものは飛ばし、足りないものだけを入れる。既存のファイルは上書きしない

## セットアップ

```sh
# 1. Command Line Tools（ダイアログが出たらインストールを完了させる）
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. cloneしてセットアップ
git clone https://github.com/97kuek/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh

# 4. Gitの名前とメールアドレス
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"

# 5. 新しい設定でzshを起動する
exec zsh

# 6. Claude CodeとCodexにログインする
claude    # 起動したら /login
codex     # 起動したら画面の案内に従う
```

- 既存のファイルとぶつかったときは、リンクを作る前に一覧を出して止まる
  - 表示されたファイルを退避して（例：`mv ~/.zshrc ~/.zshrc.before-dotfiles`）、もう一度`./install.sh`を実行する

## よく使うコマンド

| コマンド | やること |
| --- | --- |
| `./install.sh` | 全体をセットアップし直す。Brewfileや設定を変えたあとにも使う |
| `./ai/install.sh` | Claude CodeとCodexの部分だけを反映する |
| `ai-update` | Claude Code、Codex、プラグイン、スキルをまとめて最新にする |
| `ai-doctor` | Claude CodeとCodexが、このリポジトリの宣言どおりになっているかを確かめる |
| `claude-<名前>`、`codex-<名前>` | 別のアカウントで起動する（例：`claude-neoai`） |
| `ai-use <名前>` | 今のシェル全体を、別のアカウントに切り替える |
| `ai-ls` | アカウントの一覧 |

## 変更したいとき

- 編集するのは、`~`にあるファイルではなく、このリポジトリのファイル
  - `~/.zshrc`などは、このリポジトリへのリンクになっている

| やりたいこと | 編集するファイル | 反映のしかた |
| --- | --- | --- |
| zshのalias、環境変数、プラグイン | `zsh/.config/zsh/config.zsh` | `exec zsh` |
| APIトークンなど、Gitに入れたくない設定 | `~/.config/zsh/local/<好きな名前>.zsh` | `exec zsh` |
| Gitの設定 | `git/.gitconfig` | すぐに反映される |
| SSHの接続先 | `ssh/.ssh/config`（公開したくないものは`~/.ssh/config.d/*.conf`） | すぐに反映される |
| プロンプトの見た目 | `starship/.config/starship.toml` | すぐに反映される |
| ターミナルの見た目やキー | `ghostty/.config/ghostty/config.ghostty` | Ghosttyで`⌘⇧,` |
| VS Codeの設定やキー | `vscode/Library/Application Support/Code/User/`の`settings.json`、`keybindings.json` | すぐに反映される |
| ツール、アプリ、VS Codeの拡張機能を追加する | `Brewfile` | `./install.sh` |
| ClaudeとCodexへの共通の指示 | `ai/AGENTS.md` | 次に起動したセッションから |
| Claude Codeの設定や許可のルール | `ai/claude/settings.json` | `./ai/install.sh` |
| スキルを追加・削除する | `ai/skills.txt` | `./ai/install.sh` |
| プラグインを追加する | `ai/plugins.txt` | `./ai/install.sh` |
| MCPサーバーを追加する | `ai/mcp.txt` | `./ai/install.sh` |
| シェルスクリプトを直す | `install.sh`、`ai/*.sh` | push前に`shellcheck install.sh ai/*.sh`。pushするとGitHub Actionsでも確かめる |

## ドキュメント

| ドキュメント | 内容 |
| --- | --- |
| [docs/how-it-works.md](docs/how-it-works.md) | dotfiles全体の仕組み。Stow、Homebrew、zshやGhosttyなど各設定の中身 |
| [docs/ai.md](docs/ai.md) | Claude CodeとCodexの管理。アカウント、指示、許可のルール、スキルの入れ方 |
| [docs/skills.md](docs/skills.md) | 入れているスキルの一覧。内容、呼び方、配布元 |

## 注意

- APIトークンや鍵などの秘密情報は、このリポジトリにコミットしない
  - `~/.config/zsh/local/`や`~/.ssh/config.d/`など、Gitの外に置く場所を用意している
- このリポジトリは公開されている
  - 会社のアカウントで作ったスキルや、社外に出せない情報も入れない
  - ライセンスはMIT（[LICENSE](LICENSE)）
