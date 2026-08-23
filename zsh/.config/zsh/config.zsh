export LANG=en_US.UTF-8
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  [[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

WORDCHARS=''

# --- AI CLI profiles ---------------------------------------------------------
# Claude Code reads CLAUDE_CONFIG_DIR and Codex CLI reads CODEX_HOME, and both
# keep their credentials inside that directory. Pointing them elsewhere gives a
# fully separate account. "personal" keeps the default ~/.claude and ~/.codex;
# every other profile lives under ~/.ai/<profile>/. Add profiles here.
AI_PROFILES=(personal work)

_ai_profile_dir() {
  case "$1" in
    personal) print -r -- "$HOME/.$2" ;;
    *)        print -r -- "$HOME/.ai/$1/$2" ;;
  esac
}

# Share one settings.json so a secondary profile does not drift from the
# personal one. Claude writes through the symlink, so edits stay in sync.
_ai_link_shared_settings() {
  local dir=$1
  [[ $dir == "$HOME/.claude" ]] && return 0
  [[ -e $dir/settings.json ]] && return 0
  [[ -f $HOME/.claude/settings.json ]] || return 0
  ln -s "$HOME/.claude/settings.json" "$dir/settings.json"
}

_ai_activate() {
  local profile=$1
  export AI_PROFILE=$profile
  export CLAUDE_CONFIG_DIR="$(_ai_profile_dir "$profile" claude)"
  export CODEX_HOME="$(_ai_profile_dir "$profile" codex)"
  mkdir -p -- "$CLAUDE_CONFIG_DIR" "$CODEX_HOME" || return
  _ai_link_shared_settings "$CLAUDE_CONFIG_DIR"
}

# ai <profile> [command ...] — run a single command under a profile.
# The surrounding shell is untouched, so there is no "I forgot to switch back".
ai() {
  emulate -L zsh
  local profile=${1-}
  if [[ -z $profile || $profile == -h || $profile == --help ]]; then
    print -r -- "usage: ai <${(j:|:)AI_PROFILES}> [command ...]  (default: claude)"
    return 1
  fi
  shift
  if (( ! ${AI_PROFILES[(Ie)$profile]} )); then
    print -u2 -r -- "ai: unknown profile: $profile"
    return 1
  fi
  (( $# )) || set -- claude
  ( _ai_activate "$profile" && "$@" )
}

# ai-use <profile> — switch the current shell instead. Shown in the prompt.
ai-use() {
  emulate -L zsh
  local profile=${1-}
  if (( ! ${AI_PROFILES[(Ie)$profile]} )); then
    print -u2 -r -- "usage: ai-use <${(j:|:)AI_PROFILES}>"
    return 1
  fi
  _ai_activate "$profile"
}

# claude-<profile> / codex-<profile> shorthands, e.g. claude-work.
for _ai_profile in $AI_PROFILES; do
  eval "claude-${_ai_profile}() { ai ${_ai_profile} claude \"\$@\"; }"
  eval "codex-${_ai_profile}() { ai ${_ai_profile} codex \"\$@\"; }"
done
unset _ai_profile

# Load secrets and machine-specific settings that are not tracked by Git.
for file in "$HOME"/.config/zsh/local/*.zsh(N); do
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
