export LANG=en_US.UTF-8
export EDITOR=nvim

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

# Load secrets and machine-specific settings that are not tracked by Git.
for file in "$HOME"/.config/zsh/local/*.zsh(N); do
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
