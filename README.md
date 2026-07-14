# dotfiles

macOSの開発環境を再現するための個人設定です。GNU Stowでホームディレクトリへリンクします。

## 新しいMacでのセットアップ

1. Homebrewをインストールする。
2. このリポジトリを `~/dotfiles` にcloneする。
3. `./install.sh` を実行する。
4. `~/.gitconfig.local` にGitの個人情報を設定する。

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```

秘密情報や会社・端末固有の設定は、Gitにコミットせず次へ置きます。

- Zsh: `~/.config/zsh/local/*.zsh`
- Git: `~/.gitconfig.local`

## 手動操作

```sh
# 全設定をリンク
stow --target="$HOME" zsh git starship

# 特定の設定だけ解除
stow --delete --target="$HOME" zsh

# Homebrewの現在状態からBrewfileを更新
brew bundle dump --file="$HOME/dotfiles/Brewfile" --force
```
