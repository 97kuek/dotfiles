#!/bin/sh
# ClaudeとCodexのプラグイン、スキル、共通の指示、Claude Codeの設定を導入する。
# ../install.sh から呼ばれるほか、AIまわりだけを入れ直したいときは単独で実行できる。
set -eu

. "$(dirname -- "$0")/lib.sh"

# --- プラグイン --------------------------------------------------------------

add_marketplace() {
  run_cli "$1" "$2" plugin marketplace add "$3" >/dev/null 2>&1
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
      label=$(account_label "$cli" "$dir")
      installed=$(installed_plugins "$cli" "$dir")

      config_lines "$AI_DIR/marketplaces.txt" | while read -r name source clis; do
        targets_include "${clis:-}" "$cli" || continue
        has_marketplace "$cli" "$dir" "$name" && continue
        if add_marketplace "$cli" "$dir" "$source"; then
          echo "  $label: 配布元 $name を登録しました。"
        else
          warn "$label への配布元 $name の登録に失敗しました。手動で追加してください。"
        fi
      done

      declared_plugins "$cli" | while read -r plugin; do
        printf '%s\n' "$installed" | grep -qxF "$plugin" && continue
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

# 共通の置き場所 ~/.agents/skills に、宣言したスキルを集める。
collect_skills() {
  mkdir -p "$SKILLS_HUB"

  config_lines "$AI_DIR/skills.txt" | awk '{ print $1 }' | sort -u | while read -r repo; do
    fetch_repo "$repo"
  done

  config_lines "$AI_DIR/skills.txt" | while read -r repo path; do
    src="$SKILL_REPOS/$repo/$path"
    if [ ! -f "$src/SKILL.md" ]; then
      warn "$repo に $path/SKILL.md が見つかりません。"
      continue
    fi
    link_path "$src" "$SKILLS_HUB/$(basename "$path")"
  done

  for skill in "$AI_DIR"/skills/*/; do
    [ -d "$skill" ] || continue
    link_path "${skill%/}" "$SKILLS_HUB/$(basename "$skill")"
  done

  prune_skill_links "$SKILLS_HUB"
}

# Claude Codeは ~/.agents/skills を読まないため、各アカウントの skills/ へリンクする。
# ~/.agents/skills には他のツールが入れたスキルもあるので、宣言したものだけを対象にする。
# 同じ実体を指すスキルは1回だけ読み込まれるので、複数の場所にリンクしても重複しない。
link_skills_to_claude() {
  config_dirs claude | while read -r dir; do
    declared_skills | while read -r name; do
      [ -d "$SKILLS_HUB/$name" ] || continue
      link_path "$SKILLS_HUB/$name" "$dir/skills/$name"
    done
    prune_skill_links "$dir/skills"
  done
}

# 宣言から消したスキルのリンクを片付ける。このdotfilesが作ったリンクだけが対象。
prune_skill_links() {
  for link in "$1"/*; do
    is_managed_link "$link" || continue
    declared_skills | grep -qxF "$(basename "$link")" && continue
    rm "$link"
    echo "  削除: $link"
  done
}

# --- 共通の指示と設定 --------------------------------------------------------

# ai/AGENTS.md を、各CLI・各アカウントの指示ファイルとしてリンクする。
link_instructions() {
  for cli in $AI_CLIS; do
    config_dirs "$cli" | while read -r dir; do
      link_path "$AI_DIR/AGENTS.md" "$dir/$(instructions_name "$cli")"
    done
  done
}

# Claude Codeの設定を、各アカウントにリンクする。
link_claude_settings() {
  config_dirs claude | while read -r dir; do
    link_path "$AI_DIR/claude/settings.json" "$dir/settings.json"
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

echo "共通の指示とClaude Codeの設定をリンクします。"
link_instructions
link_claude_settings
