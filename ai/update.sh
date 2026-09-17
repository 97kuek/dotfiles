#!/bin/sh
# ClaudeとCodexの本体、プラグイン、スキルをまとめて最新にする。ai-update から呼ばれる。
set -eu

. "$(dirname -- "$0")/lib.sh"

echo "[1/3] ClaudeとCodexの本体を更新します。"
if command -v claude >/dev/null 2>&1; then
  claude update || warn "Claude Codeを更新できませんでした。"
else
  warn "claude が見つかりません。../install.sh で入れてください。"
fi
if brew list --cask codex >/dev/null 2>&1; then
  brew upgrade --cask codex || warn "Codexを更新できませんでした。"
elif command -v codex >/dev/null 2>&1; then
  warn "codex がHomebrew以外から入っているため更新を飛ばします。Brewfileの cask \"codex\" に揃えてください。"
else
  warn "codex が見つかりません。../install.sh で入れてください。"
fi

echo "[2/3] プラグインを更新します。"
for cli in $AI_CLIS; do
  command -v "$cli" >/dev/null 2>&1 || continue
  config_dirs "$cli" | while read -r dir; do
    label=$(account_label "$cli" "$dir")
    echo "  $label"
    case $cli in
      claude)
        run_cli claude "$dir" plugin marketplace update >/dev/null 2>&1 ||
          warn "$label の配布元を更新できませんでした。"
        installed_plugins claude "$dir" | while read -r plugin; do
          if run_cli claude "$dir" plugin update --yes "$plugin" >/dev/null 2>&1; then
            echo "    $plugin"
          else
            warn "$label の $plugin を更新できませんでした。"
          fi
        done
        ;;
      codex)
        # Codexにはプラグインごとの更新コマンドがないため、配布元の取得内容を更新する。
        run_cli codex "$dir" plugin marketplace upgrade >/dev/null 2>&1 ||
          warn "$label の配布元を更新できませんでした。"
        ;;
    esac
  done
done

echo "[3/3] スキルを取得し直し、宣言に合わせます。"
sh "$AI_DIR/install.sh"

echo "更新が完了しました。起動中のセッションは再起動すると反映されます。"
