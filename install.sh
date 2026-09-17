#!/bin/sh
set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGES="zsh git starship ghostty ssh"

if ! command -v brew >/dev/null 2>&1; then
  echo "エラー: Homebrewが必要です。https://brew.sh/ からインストールしてください。" >&2
  exit 1
fi

echo "[1/5] Homebrewパッケージをインストールします。"
brew bundle --file="$DOTFILES_DIR/Brewfile"

# Claude Codeは自動更新される公式インストーラーで入れる。Codexは Brewfile の cask で入る。
export PATH="$HOME/.local/bin:$PATH"
if ! command -v claude >/dev/null 2>&1; then
  echo "  Claude Codeをインストールします。"
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo "[2/5] ローカル設定の保存先を用意します。"
mkdir -p "$HOME/.config/zsh/local"
touch "$HOME/.gitconfig.local"
mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/config.d"

echo "[3/5] 既存ファイルとの競合を確認します。"
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

echo "[4/5] dotfilesをホームディレクトリへリンクします。"
stow --restow --target="$HOME" $PACKAGES

# AIのCLIは実行時の状態（履歴・セッション・ログ）を設定と同じ場所に書くため、
# ~/.claude と ~/.codex をstowの管理対象にはしない。宣言したものだけを ai/install.sh が入れる。
echo "[5/5] ClaudeとCodexのプラグイン、スキル、共通の設定を導入します。"
sh "$DOTFILES_DIR/ai/install.sh"

echo "セットアップが完了しました。新しいシェルは 'exec zsh' で開始できます。"
echo "Gitの個人情報は ~/.gitconfig.local に設定してください。"
