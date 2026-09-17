# dotfiles

> macOSの開発環境を再現するための個人用dotfiles

Zsh、Git、Starship、Ghostty、SSHの設定をGNU Stowで`~`に配置する。
ツールとアプリは`Brewfile`からインストールする。
ClaudeとCodexのスキル・プラグインも`install.sh`から復元する。

仕組みの詳しい説明は[docs/how-it-works.md](docs/how-it-works.md)、
入れているスキルの一覧は[docs/skills.md](docs/skills.md)にある。

## セットアップ

```sh
# 1. Command Line Tools（ダイアログでインストールを完了させる）
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. clone してセットアップ
git clone https://github.com/97kuek/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh

# 4. Gitの名前とメールアドレス
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"

# 5. Zshを起動
exec zsh
```

既存ファイルと競合する場合は、リンクを作る前に競合したファイルの一覧が表示される。
表示されたファイルを退避して、もう一度`./install.sh`を実行する。

## 構成

Stowのパッケージごとにディレクトリを分けている。`install.sh`が`~`へリンクする。

| パッケージ | 編集するファイル | リンク先 |
| --- | --- | --- |
| `zsh` | `zsh/.zshrc`, `zsh/.config/zsh/*.zsh` | `~/.zshrc`, `~/.config/zsh/*.zsh` |
| `git` | `git/.gitconfig`, `git/.config/git/ignore` | `~/.gitconfig`, `~/.config/git/ignore` |
| `starship` | `starship/.config/starship.toml` | `~/.config/starship.toml` |
| `ghostty` | `ghostty/.config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` |
| `ssh` | `ssh/.ssh/config` | `~/.ssh/config` |

`ai/`はStowのパッケージではない。`~/.claude`と`~/.codex`は履歴やセッションなどの
実行時の状態を設定と同じ場所に書くため、ディレクトリごとリンクすると差分が埋もれる。
`install.sh`が必要なものだけを個別に処理する。

| ファイル | 役割 |
| --- | --- |
| `ai/install.sh` | 下の3つを読んで、プラグインとスキルを導入する。単独でも実行できる |
| `ai/plugins.txt` | 外部プラグインの一覧。CLIごと・アカウントごとにコマンドで導入する |
| `ai/marketplaces.txt` | プラグインの配布元。未登録のものだけを登録する |
| `ai/skills.txt` | GitHubで配布されているスキルの一覧。取得して`~/.agents/skills/`へリンクする |
| `ai/skills/<name>/SKILL.md` | 自作スキル。`~/.agents/skills/`へリンクする |

秘密情報と端末固有の設定はリポジトリの外に置き、自動で読み込む。

| ファイル | 用途 |
| --- | --- |
| `~/.config/zsh/local/*.zsh` | Zshの秘密情報・端末固有の設定 |
| `~/.gitconfig.local` | Gitの名前とメールアドレス |
| `~/.ssh/config.d/*.conf` | 公開したくないSSHホスト |
| `~/.ssh/id_*` | SSHの鍵 |

## Claude / Codexのアカウント切り替え

```sh
ai-new work         # プロファイルを作る（初回だけ）。そのあと ./ai/install.sh
claude-work         # workのアカウントで起動する。初回は /login でログインする
codex-work          # 同じくCodex。初回は codex login
claude              # 既定のアカウント
ai-ls               # プロファイル一覧
ai-use work         # 今のシェル全体を切り替える
```

## Claude / Codexのスキル

スキルの入れ方は3つある。どれも中身はこのリポジトリに置かず、宣言だけを書く（自作は除く）。

| 入れたいもの | 書く場所 | 導入先 |
| --- | --- | --- |
| 複数のスキルやフックをまとめて配っているもの | `ai/plugins.txt` | CLIごと・アカウントごと |
| GitHubにあるスキルを1つだけ | `ai/skills.txt` | `~/.agents/skills/`（ClaudeとCodexで共通） |
| 自作のスキル | `ai/skills/<name>/` | `~/.agents/skills/`（ClaudeとCodexで共通） |

```sh
./ai/install.sh                      # 宣言を追加・削除したあとに実行する。スキルの更新も兼ねる

claude plugin list                   # 導入済みのプラグイン
ls -l ~/.agents/skills               # 導入済みのスキル
claude plugin update <プラグイン>     # プラグインの更新
codex plugin marketplace upgrade     # Codex側の更新
```

設計の理由は[docs/how-it-works.md](docs/how-it-works.md)、
スキルごとの内容と配布元は[docs/skills.md](docs/skills.md)にまとめている。

## Ghosttyのキーバインド

このリポジトリで定義しているもの。

| 操作 | キー |
| --- | --- |
| 右に分割 | `Ctrl+Shift+V` |
| 下に分割 | `Ctrl+Shift+H` |
| 分割間を移動 | `Ctrl+H` / `Ctrl+J` / `Ctrl+K` / `Ctrl+L`（左/下/上/右） |
| 分割を閉じる | `Ctrl+X` |
| 分割のサイズ変更 | `Ctrl+,` / `Ctrl+.` / `Ctrl+;` / `Ctrl+'`（左/右/下/上に10） |
| スクロール | `Ctrl+Shift+K` / `Ctrl+Shift+J`（上/下に3行） |
| 改行を入力 | `Shift+Enter` |
| 単語単位で削除 | `Alt+Backspace` / `Shift+Backspace` |

Ghostty標準のキーバインドも上書きしていないので、そのまま使える。

| 操作 | キー |
| --- | --- |
| 右に分割 / 下に分割 | `⌘D` / `⌘⇧D` |
| 次 / 前の分割へ | `⌘]` / `⌘[` |
| 方向で分割間を移動 | `⌘⌥` + 矢印 |
| 分割のサイズ変更 | `⌘⌃` + 矢印 |
| 分割のサイズを均等に | `⌘⌃=` |
| 分割を閉じる | `⌘W` |
| 新しいタブ / ウィンドウ | `⌘T` / `⌘N` |

Ghosttyのキーバインドはキー入力を消費するため、`Ctrl+H` `Ctrl+J` `Ctrl+K` `Ctrl+L` `Ctrl+X`は
シェルへ渡らない。`Ctrl+L`の画面クリア、`Ctrl+K`の行削除、`Ctrl+X`のプレフィックスは効かない。
`keybind = performable:ctrl+l=goto_split:right`のように`performable:`を付けると、
移動先の分割があるときだけGhosttyが処理し、ないときはシェルへ渡すようになる。

## 注意

- APIトークンなどの秘密情報は、このリポジトリへcommitしない。
- SSHの秘密鍵は`ssh/`配下に置かない。`.gitignore`で`ssh/.ssh/config`以外を除外している。
- `install.sh`は何度実行しても同じ結果になる。設定を変えたあとの再適用にも使える。
- 導入済みのプラグインと、リンク済みのスキルは飛ばす。リンク先に同じ名前の実体が
  あるときは、上書きせずに警告を出す。
