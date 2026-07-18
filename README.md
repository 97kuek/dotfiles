# dotfiles

> macOSの開発環境と普段使う設定を、新しいMacで再現するための個人用リポジトリ

- 設定ファイルの実体をこのリポジトリに置き、[GNU Stow](https://www.gnu.org/software/stow/)でホームディレクトリへシンボリックリンクする。

## 管理しているもの

| パッケージ | 配置先 | 内容 |
| --- | --- | --- |
| `zsh` | `~/.zshrc`, `~/.zprofile`, `~/.config/zsh` | シェル、補完、履歴検索、ローカル設定の読込 |
| `git` | `~/.gitconfig` | 共通Git設定とローカル個人情報の読込 |
| `starship` | `~/.config/starship.toml` | プロンプトの見た目 |
| `Brewfile` | Homebrew | CLIツールとGUIアプリの一覧 |

## 新しいMacのセットアップ

### 1. Command Line Toolsを導入する

```sh
xcode-select --install
```

すでに導入済みなら、この手順はスキップできます。

### 2. Homebrewを導入する

[Homebrew公式サイト](https://brew.sh/)に掲載されているインストールコマンドを実行します。
インストール後、次で利用できることを確認します。

```sh
brew --version
```

### 3. リポジトリをcloneする

```sh
git clone https://github.com/97kuek/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 4. セットアップを実行する

```sh
./install.sh
```

このスクリプトは次を行います。

1. `Brewfile`に記載したツールとアプリをインストールする
2. ローカル設定用のディレクトリとファイルを用意する
3. Stowで各設定をホームディレクトリへリンクする

途中でStowが既存ファイルとの競合を報告した場合、そのファイルをバックアップしてから再実行してください。既存ファイルを自動削除・上書きすることはありません。

### 5. Gitの個人情報を設定する

`~/.gitconfig.local`はGit管理されません。次のように設定します。

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```

反映を確認します。

```sh
git config --global user.name
git config --global user.email
```

### 6. シェルを読み直す

```sh
exec zsh
```

## 設定内容

### Zsh

| 項目 | 設定 | 設定ファイル |
| --- | --- | --- |
| 言語 | `en_US.UTF-8` | `zsh/.config/zsh/config.zsh` |
| エディタ | `nvim` | `zsh/.config/zsh/config.zsh` |
| ユーザーコマンド | `~/.local/bin`を`PATH`へ追加 | `zsh/.zshrc` |
| プロンプト | Starshipを利用 | `zsh/.config/zsh/config.zsh` |
| 入力候補 | `zsh-autosuggestions` | `zsh/.config/zsh/config.zsh` |
| シンタックス色分け | `zsh-syntax-highlighting` | `zsh/.config/zsh/config.zsh` |
| 端末固有設定 | `~/.config/zsh/local/*.zsh`を読込 | `zsh/.config/zsh/config.zsh` |

### キーバインディング

| キー | 動作 |
| --- | --- |
| `↑` | 入力中の文字列を前方一致で検索し、古い履歴を表示 |
| `↓` | 入力中の文字列を前方一致で検索し、新しい履歴を表示 |

使用例：

1. `git`と入力する
2. `↑`を押す
3. 過去に実行した`git`で始まるコマンドだけを順に表示する

単語移動や削除では、記号も単語の区切りとして扱います。たとえば`path/to/file`を単語単位で移動すると、`/`の位置で止まります。

```zsh
WORDCHARS=''
```

### Starshipプロンプト

| 表示 | 内容 |
| --- | --- |
| OS・ユーザー名 | 現在のOSとログインユーザー |
| ディレクトリ | 現在位置。長いパスは3階層までに省略 |
| Git | ブランチ名、変更状態、リモートとの差分 |
| 開発言語 | 利用中の言語とバージョン |
| 環境 | Docker、Conda、Pixi |
| 時刻 | 24時間表記の現在時刻 |
| 入力記号 | 成功時は緑、失敗時は赤、Viモードでは状態別に色分け |

対応している言語：

- C / C++
- Rust
- Go
- Node.js / Bun
- PHP
- Java / Kotlin
- Haskell
- Python

### Git

| 項目 | 設定 |
| --- | --- |
| デフォルトブランチ | `main` |
| fetch | 不要になったリモート追跡ブランチを削除 |
| pull | fast-forwardできる場合だけ更新 |
| 氏名・メール | Git管理外の`~/.gitconfig.local`から読込 |

### Homebrew

`Brewfile`から、主に次のツールを導入します。

| 分類 | 内容 |
| --- | --- |
| シェル | Zsh、Starship、補完・色分けプラグイン |
| 開発ツール | GitHub CLI、Node.js、uv、CocoaPods |
| ターミナル | tmux、Ghostty |
| モバイル開発 | Android Studio、Flutter |
| その他 | GNU Stow、MacTeX、CodexBar |

不要なアプリは、セットアップ前に`Brewfile`から該当行を削除してください。

## 自分用にカスタマイズする

### リポジトリをforkして使う

1. GitHubでこのリポジトリをforkする
2. 自分のリポジトリをcloneする
3. 設定を変更する
4. 変更をcommitしてpushする

```sh
git clone https://github.com/YOUR_NAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### よく変更する場所

| 変更したいもの | ファイル |
| --- | --- |
| CLI・GUIアプリ | `Brewfile` |
| Zshの共通設定 | `zsh/.config/zsh/config.zsh` |
| キーバインディング | `zsh/.config/zsh/config.zsh` |
| `PATH` | `zsh/.zshrc` |
| プロンプトの色・表示項目 | `starship/.config/starship.toml` |
| Gitの共通動作 | `git/.gitconfig` |
| 秘密情報・端末固有設定 | `~/.config/zsh/local/*.zsh` |

設定変更後の反映方法：

| 対象 | コマンド |
| --- | --- |
| Zsh | `source ~/.zshrc` |
| Starship | 通常は即時反映。必要なら`exec zsh` |
| Brewfile | `brew bundle --file=~/dotfiles/Brewfile` |
| シンボリックリンク | `stow --restow --target="$HOME" zsh git starship` |

## 端末固有・秘密の設定

Zshの秘密情報、会社固有のalias、端末固有のPATHなどは、`~/.config/zsh/local/`内の任意の`*.zsh`へ保存します。

```sh
# ~/.config/zsh/local/work.zsh
export EXAMPLE_API_TOKEN="..."
alias work-project='cd ~/Developer/work-project'
```

このディレクトリの`*.zsh`は`.gitignore`で除外されます。ただし、トークンや秘密鍵をdotfiles配下の別ファイルへ保存しないよう注意してください。

## 日常的な操作

### 変更を反映する

設定ファイルはシンボリックリンクされているため、通常は`~/dotfiles`内を編集すれば即座に反映されます。Zsh設定の変更後は次で読み直せます。

```sh
source ~/.zshrc
```

### リンクを再作成する

```sh
cd ~/dotfiles
stow --restow --target="$HOME" zsh git starship
```

### 特定パッケージのリンクを解除する

```sh
cd ~/dotfiles
stow --delete --target="$HOME" zsh
```

リンクだけが解除され、リポジトリ内の設定ファイルは削除されません。

### Homebrewの構成を更新する

アプリを追加・削除した後、現在の構成から`Brewfile`を再生成できます。

```sh
brew bundle dump --file="$HOME/dotfiles/Brewfile" --force
```

生成後は意図しないパッケージが含まれていないか、差分を確認します。

```sh
git -C ~/dotfiles diff -- Brewfile
```

### 最新設定を別のMacへ反映する

```sh
cd ~/dotfiles
git pull --ff-only
./install.sh
```

## トラブルシューティング

### `existing target is neither a link nor a directory`と表示される

Stowのリンク先に同名の実ファイルがあります。内容を確認して別の場所へバックアップし、もう一度`./install.sh`を実行します。`stow --adopt`は既存ファイルをリポジトリ側へ取り込むため、意図を理解している場合を除いて使いません。

### GitHub CLIがサンドボックス内で未認証と表示される

macOS Keychainに保存した認証情報をサンドボックスから読み取れない場合があります。通常のターミナルで`gh auth status`を確認してください。

### 設定を元に戻したい

すべてのリンクを解除します。

```sh
cd ~/dotfiles
stow --delete --target="$HOME" zsh git starship
```

その後、必要に応じてバックアップした元ファイルをホームディレクトリへ戻します。
