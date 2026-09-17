#!/bin/sh
# ClaudeとCodexの状態が、dotfilesの宣言どおりになっているかを確かめる。ai-doctor から呼ばれる。
# 問題があれば終了ステータス1で終わる。
set -u

. "$(dirname -- "$0")/lib.sh"

problems=$(mktemp)
notes=$(mktemp)
trap 'rm -f "$problems" "$notes"' EXIT

ok() {
  echo "  ✓ $1"
}

ng() {
  echo "  ✗ $1"
  echo x >>"$problems"
}

note() {
  echo "  ⚠ $1"
  echo x >>"$notes"
}

section() {
  echo
  echo "■ $1"
}

# $2 が $1 を指すリンクになっているか。
check_link() {
  if [ "$2" -ef "$1" ]; then
    ok "$3"
  elif [ -L "$2" ] && [ ! -e "$2" ]; then
    ng "$3 のリンクが壊れています"
  elif [ -e "$2" ]; then
    ng "$3 がdotfilesへのリンクではありません"
  else
    ng "$3 がありません"
  fi
}

tilde() {
  case $1 in
    "$HOME"/*) echo "~${1#"$HOME"}" ;;
    *) echo "$1" ;;
  esac
}

section "本体"
if command -v claude >/dev/null 2>&1; then
  ok "claude $(claude --version 2>/dev/null | awk '{ print $1 }')（$(tilde "$(command -v claude)")）"
else
  ng "claude が見つかりません"
fi
if command -v codex >/dev/null 2>&1; then
  if brew list --cask codex >/dev/null 2>&1; then
    ok "codex $(codex --version 2>/dev/null | awk '{ print $NF }')（Homebrew）"
  else
    note "codex がHomebrew以外から入っています（$(command -v codex)）"
  fi
else
  ng "codex が見つかりません"
fi
command -v jq >/dev/null 2>&1 || ng "jq が見つかりません"

section "共通の指示（ai/AGENTS.md）"
for cli in $AI_CLIS; do
  for dir in $(config_dirs "$cli"); do
    check_link "$AI_DIR/AGENTS.md" "$dir/$(instructions_name "$cli")" \
      "$(account_label "$cli" "$dir")  $(tilde "$dir")/$(instructions_name "$cli")"
  done
done

section "Claude Codeの設定（ai/claude/settings.json）"
for dir in $(config_dirs claude); do
  check_link "$AI_DIR/claude/settings.json" "$dir/settings.json" \
    "$(account_label claude "$dir")  $(tilde "$dir")/settings.json"
done
if ! git -C "$DOTFILES_DIR" diff --quiet -- ai/claude/settings.json 2>/dev/null; then
  note "Claude Codeが設定を書き換えています。git diff ai/claude/settings.json で確認してください"
fi

section "プラグイン（ai/plugins.txt）"
for cli in $AI_CLIS; do
  command -v "$cli" >/dev/null 2>&1 || continue
  for dir in $(config_dirs "$cli"); do
    label=$(account_label "$cli" "$dir")
    installed=$(installed_plugins "$cli" "$dir")
    declared=$(declared_plugins "$cli")
    total=0
    count=0
    for plugin in $declared; do
      total=$((total + 1))
      if printf '%s\n' "$installed" | grep -qxF "$plugin"; then
        count=$((count + 1))
      else
        ng "$label  $plugin が入っていません"
      fi
    done
    [ "$count" -eq "$total" ] && ok "$label  宣言した $total 個がすべて入っています"
    for plugin in $installed; do
      is_builtin_plugin "$plugin" && continue
      printf '%s\n' "$declared" | grep -qxF "$plugin" ||
        note "$label  $plugin は plugins.txt にありません"
    done
  done
done

section "スキル（ai/skills.txt、ai/skills/）"
for name in $(declared_skills); do
  if [ -f "$SKILLS_HUB/$name/SKILL.md" ]; then
    ok "$name"
  else
    ng "$name が $(tilde "$SKILLS_HUB") にありません"
  fi
done
for dir in $(config_dirs claude); do
  label=$(account_label claude "$dir")
  total=0
  count=0
  for name in $(declared_skills); do
    total=$((total + 1))
    if [ -f "$dir/skills/$name/SKILL.md" ]; then
      count=$((count + 1))
    else
      ng "$label  $name が $(tilde "$dir")/skills にありません"
    fi
  done
  [ "$count" -eq "$total" ] && ok "$label  宣言した $total 個をすべてリンクしています"
done
for path in "$SKILLS_HUB"/* "$HOME"/.claude/skills/* "$AI_HOME"/*/claude/skills/*; do
  [ -L "$path" ] && [ ! -e "$path" ] && ng "壊れたリンク: $(tilde "$path")"
done
others=""
for path in "$SKILLS_HUB"/*; do
  [ -e "$path" ] || continue
  name=$(basename "$path")
  declared_skills | grep -qxF "$name" || others="$others $name"
done
if [ -n "$others" ]; then
  note "$(tilde "$SKILLS_HUB") に他のツールが置いたスキルがあり、Codexにも見えています:$others"
fi

echo
problem_count=$(wc -l <"$problems" | tr -d ' ')
note_count=$(wc -l <"$notes" | tr -d ' ')
if [ "$problem_count" -eq 0 ]; then
  echo "問題はありません（注意 $note_count 件）。"
else
  echo "問題 $problem_count 件、注意 $note_count 件。多くは ./ai/install.sh で直ります。"
  exit 1
fi
