#!/bin/sh
# ClaudeとCodexのプラグインとスキルを導入する。
# ../install.sh から呼ばれるほか、スキルだけを入れ直したいときは単独で実行できる。
set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
AI_DIR="$DOTFILES_DIR/ai"
AI_CLIS="claude codex"
# ai-new で作ったアカウントの置き場所。zsh/.config/zsh/ai.zsh と揃える。
AI_HOME=${AI_HOME:-$HOME/.ai}
# スキルの共通の置き場所。Codexはここを直接読み、Claude Codeへはここからリンクする。
SKILLS_HUB="$HOME/.agents/skills"
# ai/skills.txt に書いたGitHubリポジトリの取得先。
SKILL_REPOS="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/skill-repos"

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

# 2つのパスが同じ実体を指しているかを判定する。
same_dir() {
  [ "$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd)" = "$(CDPATH= cd -P -- "$2" 2>/dev/null && pwd)" ]
}

# --- アカウント --------------------------------------------------------------

# CLIの設定ディレクトリを1行ずつ出す。既定のアカウントと、ai-new で作ったアカウント。
config_dirs() {
  echo "$HOME/.$1"
  for dir in "$AI_HOME"/*/"$1"; do
    [ -d "$dir" ] && echo "$dir"
  done
  return 0
}

# 表示用のアカウント名。
profile_name() {
  if [ "$2" = "$HOME/.$1" ]; then
    echo "既定"
  else
    basename "$(dirname "$2")"
  fi
}

# 指定したアカウントの設定ディレクトリでCLIを実行する。
run_cli() {
  run_cli_name=$1
  run_cli_dir=$2
  shift 2
  case $run_cli_name in
    claude) run_cli_var=CLAUDE_CONFIG_DIR ;;
    codex) run_cli_var=CODEX_HOME ;;
  esac
  if [ "$run_cli_dir" = "$HOME/.$run_cli_name" ]; then
    env -u "$run_cli_var" "$run_cli_name" "$@"
  else
    env "$run_cli_var=$run_cli_dir" "$run_cli_name" "$@"
  fi
}

# --- プラグイン --------------------------------------------------------------

has_marketplace() {
  case $1 in
    claude) run_cli "$1" "$2" plugin marketplace list 2>/dev/null | grep -qE "❯ +$3$" ;;
    codex) run_cli "$1" "$2" plugin marketplace list 2>/dev/null |
      awk -v n="$3" '$1 == n { found = 1 } END { exit found ? 0 : 1 }' ;;
  esac
}

add_marketplace() {
  run_cli "$1" "$2" plugin marketplace add "$3" >/dev/null 2>&1
}

has_plugin() {
  case $1 in
    claude) run_cli "$1" "$2" plugin list 2>/dev/null | grep -qF "❯ $3" ;;
    # Codexは未導入のプラグインも一覧に出すため、STATUS列で絞り込む。
    codex) run_cli "$1" "$2" plugin list 2>/dev/null |
      awk -v p="$3" '$1 == p && $0 !~ /not installed/ { found = 1 } END { exit found ? 0 : 1 }' ;;
  esac
}

add_plugin() {
  case $1 in
    claude) run_cli "$1" "$2" plugin install "$3" >/dev/null 2>&1 ;;
    codex) run_cli "$1" "$2" plugin add "$3" >/dev/null 2>&1 ;;
  esac
}

# プラグインはCLIの設定ディレクトリに入るため、CLIごと・アカウントごとに導入する。
install_plugins() {
  for cli in $AI_CLIS; do
    if ! command -v "$cli" >/dev/null 2>&1; then
      echo "  $cli: 見つからないため飛ばします。"
      continue
    fi

    config_dirs "$cli" | while read -r dir; do
      label="$cli ($(profile_name "$cli" "$dir"))"

      config_lines "$AI_DIR/marketplaces.txt" | while read -r name source clis; do
        targets_include "${clis:-}" "$cli" || continue
        has_marketplace "$cli" "$dir" "$name" && continue
        if add_marketplace "$cli" "$dir" "$source"; then
          echo "  $label: 配布元 $name を登録しました。"
        else
          warn "$label への配布元 $name の登録に失敗しました。手動で追加してください。"
        fi
      done

      config_lines "$AI_DIR/plugins.txt" | while read -r plugin clis; do
        targets_include "${clis:-}" "$cli" || continue
        if has_plugin "$cli" "$dir" "$plugin"; then
          echo "  $label: $plugin は導入済みです。"
          continue
        fi
        if add_plugin "$cli" "$dir" "$plugin"; then
          echo "  $label: $plugin を導入しました。"
        else
          warn "$label への $plugin の導入に失敗しました。配布元が登録されているか確認してください。"
        fi
      done
    done
  done
}

# --- スキル ------------------------------------------------------------------

# スキルへのリンクを作る。自分が作ったリンクだけを張り替え、実体や他人のリンクは上書きしない。
link_skill() {
  src=$1
  dest=$2
  if [ -L "$dest" ]; then
    same_dir "$dest" "$src" && return 0
    case $(readlink "$dest") in
      "$SKILL_REPOS"/* | "$AI_DIR"/skills/* | "$SKILLS_HUB"/*)
        rm "$dest"
        ;;
      *)
        warn "$dest は別の場所を指すリンクです。中身を確認してから削除してください。"
        return 0
        ;;
    esac
  elif [ -e "$dest" ]; then
    warn "$dest に実体があるためリンクしませんでした。"
    return 0
  fi
  ln -s "$src" "$dest"
  echo "  リンク: $dest"
}

# ai/skills.txt のリポジトリを取得する。取得済みなら最新にする。
fetch_repo() {
  dest="$SKILL_REPOS/$1"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only --quiet ||
      warn "$1 を更新できませんでした。前回取得した内容を使います。"
  else
    mkdir -p "$(dirname "$dest")"
    if git clone --depth 1 --quiet "https://github.com/$1.git" "$dest"; then
      echo "  取得: $1"
    else
      warn "$1 を取得できませんでした。"
    fi
  fi
}

# ai/skills.txt と ai/skills/ で宣言したスキルの名前を1行ずつ出す。
declared_skills() {
  config_lines "$AI_DIR/skills.txt" | while read -r repo path; do
    basename "$path"
  done
  for skill in "$AI_DIR"/skills/*/; do
    [ -d "$skill" ] && basename "$skill"
  done
  return 0
}

# 共通の置き場所 ~/.agents/skills に、宣言したスキルを集める。
collect_skills() {
  mkdir -p "$SKILLS_HUB"

  config_lines "$AI_DIR/skills.txt" | awk '{ print $1 }' | sort -u | while read -r repo; do
    fetch_repo "$repo"
  done

  config_lines "$AI_DIR/skills.txt" | while read -r repo path; do
    src="$SKILL_REPOS/$repo/$path"
    name=$(basename "$path")
    if [ ! -f "$src/SKILL.md" ]; then
      warn "$repo に $path/SKILL.md が見つかりません。"
      continue
    fi
    link_skill "$src" "$SKILLS_HUB/$name"
  done

  for skill in "$AI_DIR"/skills/*/; do
    [ -d "$skill" ] || continue
    name=$(basename "$skill")
    link_skill "${skill%/}" "$SKILLS_HUB/$name"
  done

  # 宣言から消したスキルのリンクを片付ける。このスクリプトが作ったリンクだけが対象。
  for link in "$SKILLS_HUB"/*; do
    [ -L "$link" ] || continue
    case $(readlink "$link") in
      "$SKILL_REPOS"/* | "$AI_DIR"/skills/*) ;;
      *) continue ;;
    esac
    declared_skills | grep -qxF "$(basename "$link")" && continue
    rm "$link"
    echo "  削除: $link"
  done
}

# Claude Codeは ~/.agents/skills を読まないため、各アカウントの skills/ へリンクする。
# ~/.agents/skills には他のツールが入れたスキルもあるので、宣言したものだけを対象にする。
# 同じ実体を指すスキルは1回だけ読み込まれるので、複数の場所にリンクしても重複しない。
link_skills_to_claude() {
  config_dirs claude | while read -r dir; do
    skills_dir="$dir/skills"
    mkdir -p "$skills_dir"

    declared_skills | while read -r name; do
      [ -d "$SKILLS_HUB/$name" ] || continue
      link_skill "$SKILLS_HUB/$name" "$skills_dir/$name"
    done

    # 宣言から消したスキルのリンクを片付ける。~/.agents/skills を指すリンクだけが対象。
    for link in "$skills_dir"/*; do
      [ -L "$link" ] || continue
      case $(readlink "$link") in
        "$SKILLS_HUB"/*) ;;
        *) continue ;;
      esac
      declared_skills | grep -qxF "$(basename "$link")" && continue
      rm "$link"
      echo "  削除: $link"
    done
  done
}

echo "AIの外部プラグインを導入します。"
install_plugins

echo "AIのスキルを集めてリンクします。"
if command -v git >/dev/null 2>&1; then
  collect_skills
else
  warn "gitが見つからないため、ai/skills.txt のスキルを取得できません。"
fi
link_skills_to_claude
