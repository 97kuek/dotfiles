#!/bin/sh
set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGES="zsh git starship ghostty ssh"
# AIのCLI。自作スキルのリンク先と、外部プラグインの導入先。
AI_CLIS="claude codex"

warn() {
  echo "警告: $1" >&2
}

# 設定ファイルから、#以降のコメントと空行を除いた行だけを取り出す。
config_lines() {
  [ -f "$1" ] || return 0
  sed 's/#.*//' "$1" | awk 'NF'
}

# 対象CLIの指定に $2 が含まれるかを判定する。指定が空なら全てのCLIが対象。
targets_include() {
  [ -n "$1" ] || return 0
  case ",$1," in
    *",$2,"*) return 0 ;;
    *) return 1 ;;
  esac
}

has_marketplace() {
  case $1 in
    claude) claude plugin marketplace list 2>/dev/null | grep -qE "❯ +$2$" ;;
    codex) codex plugin marketplace list 2>/dev/null |
      awk -v n="$2" '$1 == n { found = 1 } END { exit found ? 0 : 1 }' ;;
  esac
}

add_marketplace() {
  case $1 in
    claude) claude plugin marketplace add "$2" >/dev/null 2>&1 ;;
    codex) codex plugin marketplace add "$2" >/dev/null 2>&1 ;;
  esac
}

has_plugin() {
  case $1 in
    claude) claude plugin list 2>/dev/null | grep -qF "❯ $2" ;;
    # Codexは未導入のプラグインも一覧に出すため、STATUS列で絞り込む。
    codex) codex plugin list 2>/dev/null |
      awk -v p="$2" '$1 == p && $0 !~ /not installed/ { found = 1 } END { exit found ? 0 : 1 }' ;;
  esac
}

add_plugin() {
  case $1 in
    claude) claude plugin install "$2" >/dev/null 2>&1 ;;
    codex) codex plugin add "$2" >/dev/null 2>&1 ;;
  esac
}

# 自作スキルをリンクする。リンク先に実体があるときは上書きしない。
link_skill() {
  src=$1
  dest=$2
  if [ -L "$dest" ]; then
    [ "$(readlink "$dest")" = "$src" ] && return 0
    warn "$dest は別の場所を指すリンクです。中身を確認してから削除してください。"
    return 0
  fi
  if [ -e "$dest" ]; then
    warn "$dest に実体があるためリンクしませんでした。"
    return 0
  fi
  ln -s "$src" "$dest"
  echo "  リンク: $dest"
}

if ! command -v brew >/dev/null 2>&1; then
  echo "エラー: Homebrewが必要です。https://brew.sh/ からインストールしてください。" >&2
  exit 1
fi

echo "[1/6] Homebrewパッケージをインストールします。"
brew bundle --file="$DOTFILES_DIR/Brewfile"

echo "[2/6] ローカル設定の保存先を用意します。"
mkdir -p "$HOME/.config/zsh/local"
touch "$HOME/.gitconfig.local"
mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/config.d"

echo "[3/6] 既存ファイルとの競合を確認します。"
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

echo "[4/6] dotfilesをホームディレクトリへリンクします。"
stow --restow --target="$HOME" $PACKAGES

# AIのCLIは実行時の状態（履歴・セッション・ログ）を設定と同じ場所に書くため、
# ~/.claude と ~/.codex をstowの管理対象にはしない。
# 外部プラグインは中身を持たずコマンドで導入し、自作スキルだけをリンクする。
echo "[5/6] AIの外部プラグインを導入します。"
for cli in $AI_CLIS; do
  if ! command -v "$cli" >/dev/null 2>&1; then
    echo "  $cli: 見つからないため飛ばします。"
    continue
  fi

  config_lines "$DOTFILES_DIR/ai/marketplaces.txt" | while read -r name source clis; do
    targets_include "${clis:-}" "$cli" || continue
    if has_marketplace "$cli" "$name"; then
      continue
    fi
    if add_marketplace "$cli" "$source"; then
      echo "  $cli: 配布元 $name を登録しました。"
    else
      warn "$cli への配布元 $name の登録に失敗しました。手動で追加してください。"
    fi
  done

  config_lines "$DOTFILES_DIR/ai/plugins.txt" | while read -r plugin clis; do
    targets_include "${clis:-}" "$cli" || continue
    if has_plugin "$cli" "$plugin"; then
      echo "  $cli: $plugin は導入済みです。"
      continue
    fi
    if add_plugin "$cli" "$plugin"; then
      echo "  $cli: $plugin を導入しました。"
    else
      warn "$cli への $plugin の導入に失敗しました。配布元が登録されているか確認してください。"
    fi
  done
done

echo "[6/6] 自作のAIスキルをリンクします。"
for cli in $AI_CLIS; do
  skills_dir="$HOME/.$cli/skills"
  mkdir -p "$skills_dir"
  for skill in "$DOTFILES_DIR"/ai/skills/*/; do
    [ -d "$skill" ] || continue
    name=$(basename "$skill")
    link_skill "${skill%/}" "$skills_dir/$name"
  done
done

echo "セットアップが完了しました。新しいシェルは 'exec zsh' で開始できます。"
echo "Gitの個人情報は ~/.gitconfig.local に設定してください。"
