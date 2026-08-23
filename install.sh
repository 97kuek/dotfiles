#!/bin/sh
set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGES="zsh git starship ghostty ssh"

if ! command -v brew >/dev/null 2>&1; then
  echo "エラー: Homebrewが必要です。https://brew.sh/ からインストールしてください。" >&2
  exit 1
fi

echo "[1/4] Homebrewパッケージをインストールします。"
brew bundle --file="$DOTFILES_DIR/Brewfile"

echo "[2/4] ローカル設定の保存先を用意します。"
mkdir -p "$HOME/.config/zsh/local"
touch "$HOME/.gitconfig.local"
touch "$HOME/.gitconfig.work"
mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/config.d"

echo "[3/4] 既存ファイルとの競合を確認します。"
cd "$DOTFILES_DIR"
# --simulate はリンクを作らずに競合だけを報告する。先に見せてから実行する。
# 競合がなくても "in simulation mode" の警告は出るため、判定は終了ステータスで行う。
if ! conflicts=$(stow --simulate --restow --target="$HOME" $PACKAGES 2>&1); then
  echo "エラー: 以下のファイルがdotfilesと競合しています。" >&2
  echo "$conflicts" >&2
  echo "" >&2
  echo "対象ファイルを退避してから、もう一度 ./install.sh を実行してください。" >&2
  echo "  例: mv ~/.ssh/config ~/.ssh/config.before-dotfiles" >&2
  exit 1
fi

echo "[4/4] dotfilesをホームディレクトリへリンクします。"
stow --restow --target="$HOME" $PACKAGES

echo "セットアップが完了しました。新しいシェルは 'exec zsh' で開始できます。"
echo "Gitの個人情報は ~/.gitconfig.local に設定してください。"
