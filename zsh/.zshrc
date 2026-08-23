export PATH="$HOME/.local/bin:$PATH"

# Let CMake emit -isysroot so clang-tidy/clangd (Homebrew LLVM) find the macOS SDK headers.
if [ -z "$SDKROOT" ] && command -v xcrun > /dev/null 2>&1; then
  export SDKROOT="$(xcrun --show-sdk-path)"
fi

# Load the shared interactive zsh configuration.
if [ -r "$HOME/.config/zsh/config.zsh" ]; then
  source "$HOME/.config/zsh/config.zsh"
fi
