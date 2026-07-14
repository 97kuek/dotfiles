#!/bin/sh
set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGES="zsh git starship"

if ! command -v brew >/dev/null 2>&1; then
  echo "エラー: Homebrewが必要です。https://brew.sh/ からインストールしてください。" >&2
  exit 1
fi

echo "[1/3] Homebrewパッケージをインストールします。"
brew bundle --file="$DOTFILES_DIR/Brewfile"

echo "[2/3] ローカル設定の保存先を用意します。"
mkdir -p "$HOME/.config/zsh/local"
touch "$HOME/.gitconfig.local"

echo "[3/3] dotfilesをホームディレクトリへリンクします。"
cd "$DOTFILES_DIR"
if ! stow --restow --target="$HOME" $PACKAGES; then
  echo "エラー: 既存の設定ファイルと競合している可能性があります。" >&2
  echo "競合したファイルをバックアップしてから、もう一度 ./install.sh を実行してください。" >&2
  exit 1
fi

echo "セットアップが完了しました。新しいシェルは 'exec zsh' で開始できます。"
echo "Gitの個人情報は ~/.gitconfig.local に設定してください。"
