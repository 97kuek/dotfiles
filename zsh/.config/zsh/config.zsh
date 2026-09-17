export LANG=en_US.UTF-8
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi

# Python versions. Shims go ahead of Homebrew so the selected version wins.
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  eval "$(pyenv init - zsh)"
fi

# Node toolchains. Volta's shims pick the version pinned by each project.
if command -v volta >/dev/null 2>&1; then
  export VOLTA_HOME="$HOME/.volta"
  export PATH="$VOLTA_HOME/bin:$PATH"
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
setopt interactivecomments

# Load secrets and machine-specific settings that are not tracked by Git.
for file in "$HOME"/.config/zsh/local/*.zsh(N); do
  [[ -r "$file" && -f "$file" ]] && source "$file"
done

# AI CLI account profiles. Loaded after the local settings so they can override
# which tools and directories it manages.
[[ -r "$HOME/.config/zsh/ai.zsh" ]] && source "$HOME/.config/zsh/ai.zsh"
