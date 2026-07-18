# dotfiles

> macOSの開発環境を再現するための個人用dotfiles

- Zsh、Git、Starshipの設定をGNU Stowで配置
- CLIツールとGUIアプリを`Brewfile`からインストール
- 既存の設定ファイルは自動で削除・上書きしない

## セットアップ

1. Command Line Toolsをインストールする

```sh
xcode-select --install
```

- 表示されたダイアログでインストールを完了してから、次へ進む。

2. Homebrewをインストールする

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi
```

3. このリポジトリをcloneしてセットアップする

```sh
git clone https://github.com/97kuek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

4. Gitの名前とメールアドレスを設定する

```sh
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

- `Your Name`と`you@example.com`は自分の情報に置き換える。

5. Zshを起動する

```sh
exec zsh
```

## 主な変更先

- インストールするツール・アプリ: `Brewfile`
- Zsh: `zsh/.config/zsh/config.zsh`
- Git: `git/.gitconfig`
- Starship: `starship/.config/starship.toml`
- 秘密情報・端末固有の設定: `~/.config/zsh/local/*.zsh`

## 注意

- `./install.sh`で既存ファイルとの競合が表示された場合は、そのファイルをバックアップしてから再実行する。
- APIトークンなどの秘密情報は、このリポジトリへcommitしない。
