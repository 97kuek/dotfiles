# ai/install.sh、ai/update.sh、ai/doctor.sh が共通で使う変数と関数。
# 単独では実行せず、各スクリプトから . で読み込む。
# 変数は読み込んだ側で使うので、未使用の警告は出さない。
# shellcheck disable=SC2034

AI_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
DOTFILES_DIR=$(dirname "$AI_DIR")
AI_CLIS="claude codex"
# ai-new で作ったアカウントの置き場所。zsh/.config/zsh/ai.zsh と揃える。
AI_HOME=${AI_HOME:-$HOME/.ai}
# スキルの共通の置き場所。Codexはここを直接読み、Claude Codeへはここからリンクする。
SKILLS_HUB="$HOME/.agents/skills"
# ai/skills.txt に書いたGitHubリポジトリの取得先。
SKILL_REPOS="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/skill-repos"
# 公式インストーラーが入れる Claude Code の場所。
export PATH="$HOME/.local/bin:$PATH"

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

# --- アカウント --------------------------------------------------------------

# CLIの設定ディレクトリを1行ずつ出す。既定のアカウントと、ai-new で作ったアカウント。
config_dirs() {
  echo "$HOME/.$1"
  for dir in "$AI_HOME"/*/"$1"; do
    [ -d "$dir" ] && echo "$dir"
  done
  return 0
}

# 表示用のラベル。例: claude (既定)、claude (neoai)
account_label() {
  if [ "$2" = "$HOME/.$1" ]; then
    echo "$1 (既定)"
  else
    echo "$1 ($(basename "$(dirname "$2")"))"
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

# 導入済みのプラグインを1行ずつ出す。
installed_plugins() {
  case $1 in
    claude) run_cli "$1" "$2" plugin list --json 2>/dev/null | jq -r '.[].id' ;;
    codex) run_cli "$1" "$2" plugin list --json 2>/dev/null |
      jq -r '.installed[] | select(.installed) | .pluginId' ;;
  esac
}

# CLIが自動で入れるプラグインかどうか。宣言との比較から外す。
# @synced はclaude.aiのアカウントから同期されたもの、openai-* はCodexに最初から入っているもの。
is_builtin_plugin() {
  case $1 in
    *@synced | *@openai-primary-runtime | *@openai-bundled | *@openai-curated-remote) return 0 ;;
    *) return 1 ;;
  esac
}

# plugins.txt で、このCLIに入れると宣言したプラグインを1行ずつ出す。
declared_plugins() {
  config_lines "$AI_DIR/plugins.txt" | while read -r plugin clis; do
    targets_include "${clis:-}" "$1" && echo "$plugin"
  done
  return 0
}

# --- MCPサーバー -------------------------------------------------------------

# mcp.txt で宣言したMCPサーバーを「名前 コマンド...」の形で1行ずつ出す。
declared_mcp_servers() {
  config_lines "$AI_DIR/mcp.txt"
}

# 指定したアカウントに、その名前のMCPサーバーが登録されているか。
# Claude Codeの mcp get はサーバーを起動して接続まで試すので、設定ファイルを直接読む。
has_mcp_server() {
  case $1 in
    claude)
      if [ "$2" = "$HOME/.claude" ]; then
        state="$HOME/.claude.json"
      else
        state="$2/.claude.json"
      fi
      [ -f "$state" ] && jq -e --arg n "$3" '.mcpServers[$n] != null' "$state" >/dev/null 2>&1
      ;;
    codex)
      run_cli codex "$2" mcp list --json 2>/dev/null | jq -e --arg n "$3" 'any(.[]; .name == $n)' >/dev/null
      ;;
  esac
}

# --- リンク ------------------------------------------------------------------

# このdotfilesが作ったリンクかどうか。張り替えや片付けはこれだけを対象にする。
is_managed_link() {
  [ -L "$1" ] || return 1
  case $(readlink "$1") in
    "$AI_DIR"/* | "$SKILL_REPOS"/* | "$SKILLS_HUB"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# $2 に $1 へのリンクを作る。自分が作った古いリンクは張り替え、実体や他人のリンクは上書きしない。
link_path() {
  if [ -L "$2" ] || [ -e "$2" ]; then
    [ "$2" -ef "$1" ] && return 0
    if is_managed_link "$2"; then
      rm "$2"
    elif [ -L "$2" ]; then
      warn "$2 は別の場所を指すリンクです。中身を確認してから削除してください。"
      return 0
    else
      warn "$2 に実体があるためリンクしませんでした。退避してから再実行してください。"
      return 0
    fi
  fi
  mkdir -p "$(dirname "$2")"
  ln -s "$1" "$2"
  echo "  リンク: $2"
}

# --- スキル ------------------------------------------------------------------

# ai/skills.txt と ai/skills/ で宣言したスキルの名前を1行ずつ出す。
declared_skills() {
  config_lines "$AI_DIR/skills.txt" | while read -r _ path; do
    basename "$path"
  done
  for skill in "$AI_DIR"/skills/*/; do
    [ -d "$skill" ] && basename "$skill"
  done
  return 0
}

# --- 共通の指示と設定 --------------------------------------------------------

# Claude Codeの設定のうち、dotfilesで管理する部分。
CLAUDE_SETTINGS="$AI_DIR/claude/settings.json"

# $1 の settings.json に、dotfilesの設定を重ねた内容を出す。
# dotfilesに書いたキーはdotfilesの値になり、Claude Codeが足したキーは残る。配列は丸ごと置き換わる。
merged_claude_settings() {
  if [ -s "$1" ]; then
    jq -s '.[0] * .[1]' "$1" "$CLAUDE_SETTINGS"
  else
    jq . "$CLAUDE_SETTINGS"
  fi
}

# $1 の settings.json から、dotfilesの設定を重ねると消える許可ルールを1行ずつ出す。
# 許可ルールは配列なので、重ねるとdotfilesの内容で丸ごと置き換わる。
dropped_claude_permissions() {
  [ -s "$1" ] || return 0
  jq -r -n --slurpfile a "$1" --slurpfile b "$CLAUDE_SETTINGS" '
    ($b[0].permissions // {}) as $new
    | ($a[0].permissions // {}) | to_entries[]
    | select(.value | type == "array") | select($new[.key] != null)
    | .key as $kind | .value[] | select(. as $rule | $new[$kind] | index($rule) | not)
    | "\($kind): \(.)"'
}

# $1 の settings.json が、dotfilesの設定をすべて含んでいるか。
claude_settings_in_sync() {
  [ -f "$1" ] && [ ! -L "$1" ] &&
    [ "$(merged_claude_settings "$1" | jq -S .)" = "$(jq -S . "$1")" ]
}

# CLIごとの、共通の指示ファイルのファイル名。
instructions_name() {
  case $1 in
    claude) echo CLAUDE.md ;;
    codex) echo AGENTS.md ;;
  esac
}
