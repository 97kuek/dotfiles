#!/bin/sh
set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrewが必要です: https://brew.sh/" >&2
  exit 1
fi

brew bundle --file="$DOTFILES_DIR/Brewfile"

mkdir -p "$HOME/.config/zsh/local"
touch "$HOME/.gitconfig.local"

cd "$DOTFILES_DIR"
stow --target="$HOME" zsh git starship

echo "dotfilesのセットアップが完了しました。"
echo "Gitの個人情報は ~/.gitconfig.local に設定してください。"
