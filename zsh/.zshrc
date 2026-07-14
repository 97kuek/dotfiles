export PATH="$HOME/.local/bin:$PATH"

# Load the shared interactive zsh configuration.
if [ -r "$HOME/.config/zsh/config.zsh" ]; then
  source "$HOME/.config/zsh/config.zsh"
fi
