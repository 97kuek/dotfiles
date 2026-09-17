# AI CLI account profiles.
#
# Claude Code, Codex and similar CLIs read their configuration directory from
# an environment variable and keep their credentials inside it. Pointing that
# variable somewhere else therefore gives a fully separate account.
#
# The default profile keeps each tool where it already was ($HOME/.<command>),
# so an existing setup keeps working. Every other profile lives under $AI_HOME
# and is created on demand with `ai-new`; nothing in this repository has to be
# edited to add one. A profile only has the tools whose directory exists, e.g.
# $AI_HOME/work/claude without $AI_HOME/work/codex; the missing tools keep
# using the default account.
#
# To support another CLI, add it from ~/.config/zsh/local/*.zsh:
#   typeset -gA AI_TOOLS=(claude CLAUDE_CONFIG_DIR codex CODEX_HOME gemini GEMINI_DIR)

: ${AI_HOME:=$HOME/.ai}
# The dotfiles checkout that holds ai/install.sh, found through this file's symlink.
: ${AI_DOTFILES:=${${(%):-%x}:A:h:h:h:h}}
: ${AI_DEFAULT_PROFILE:=personal}
: ${AI_DEFAULT_TOOL:=claude}

# command -> environment variable holding that command's config directory.
typeset -gA AI_TOOLS
(( ${#AI_TOOLS} )) || AI_TOOLS=(
  claude CLAUDE_CONFIG_DIR
  codex  CODEX_HOME
)

_ai_dir() {
  local profile=$1 tool=$2
  if [[ $profile == $AI_DEFAULT_PROFILE ]]; then
    print -r -- "$HOME/.$tool"
  else
    print -r -- "$AI_HOME/$profile/$tool"
  fi
}

# The tools a profile has an account for, one per line.
_ai_profile_tools() {
  local profile=$1 tool
  for tool in ${(ko)AI_TOOLS}; do
    [[ $profile == $AI_DEFAULT_PROFILE || -d $AI_HOME/$profile/$tool ]] && print -r -- $tool
  done
}

# The default profile plus every directory under $AI_HOME, one per line.
_ai_profiles() {
  local -a found=("$AI_DEFAULT_PROFILE" $AI_HOME/*(N/:t))
  print -rl -- ${(u)found}
}

_ai_activate() {
  local profile=$1 tool dir
  local -a tools=(${(f)"$(_ai_profile_tools "$profile")"})
  for tool in ${(k)AI_TOOLS}; do
    # A tool without an account in this profile falls back to the default one.
    if (( ! ${tools[(Ie)$tool]} )); then
      unset ${AI_TOOLS[$tool]}
      continue
    fi
    dir=$(_ai_dir "$profile" "$tool")
    [[ -d $dir ]] || mkdir -p -- "$dir" || return 1
    export ${AI_TOOLS[$tool]}="$dir"
  done
  # Only a non-default profile is worth showing in the prompt.
  if [[ $profile == $AI_DEFAULT_PROFILE ]]; then
    unset AI_PROFILE
  else
    export AI_PROFILE=$profile
  fi
}

# claude-<profile>, codex-<profile>, ... for every profile and every tool.
_ai_define_shorthands() {
  local profile tool
  for profile in "$@"; do
    [[ $profile == $AI_DEFAULT_PROFILE ]] && continue
    for tool in ${(f)"$(_ai_profile_tools "$profile")"}; do
      functions[${tool}-${profile}]="ai ${(q)profile} ${(q)tool} \"\$@\""
    done
  done
}

# ai <profile> [command ...] — run one command under a profile. It runs in a
# subshell, so the surrounding shell is never left pointing at the wrong
# account.
ai() {
  emulate -L zsh
  local profile=${1-}
  local -a profiles=(${(f)"$(_ai_profiles)"})
  if [[ -z $profile || $profile == -h || $profile == --help ]]; then
    print -r -- "usage: ai <${(j:|:)profiles}> [command ...]  (default: $AI_DEFAULT_TOOL)"
    return 1
  fi
  if (( ! ${profiles[(Ie)$profile]} )); then
    print -u2 -r -- "ai: unknown profile: $profile (create it with: ai-new $profile)"
    return 1
  fi
  shift
  (( $# )) || set -- "$AI_DEFAULT_TOOL"
  ( _ai_activate "$profile" && "$@" )
}

# ai-use <profile> — switch the current shell instead of a single command.
ai-use() {
  emulate -L zsh
  local profile=${1-}
  local -a profiles=(${(f)"$(_ai_profiles)"})
  if (( ! ${profiles[(Ie)$profile]} )); then
    print -u2 -r -- "usage: ai-use <${(j:|:)profiles}>"
    return 1
  fi
  _ai_activate "$profile"
}

# ai-new <profile> [tool ...] — create a profile for the given tools (default:
# all of them) and its shorthands. Run it again to add a tool later.
ai-new() {
  emulate -L zsh
  local profile=${1-} tool
  if [[ -z $profile || $profile == *[^A-Za-z0-9._-]* ]]; then
    print -u2 -r -- "usage: ai-new <profile> [${(j:|:)${(ko)AI_TOOLS}} ...]"
    return 1
  fi
  if [[ $profile == $AI_DEFAULT_PROFILE ]]; then
    print -u2 -r -- "ai-new: $profile is the default profile"
    return 1
  fi
  shift
  (( $# )) || set -- ${(ko)AI_TOOLS}
  for tool in "$@"; do
    if [[ -z ${AI_TOOLS[$tool]-} ]]; then
      print -u2 -r -- "ai-new: unknown tool: $tool"
      return 1
    fi
  done
  for tool in "$@"; do
    mkdir -p -- "$(_ai_dir "$profile" "$tool")" || return 1
  done
  _ai_define_shorthands "$profile"
  print -r -- "created $AI_HOME/$profile for $* — start it with ${1}-${profile} and log in"
  print -r -- "then run $AI_DOTFILES/ai/install.sh to add the plugins, skills and settings to it"
}

# ai-ls — list the profiles and where each tool stores its account.
ai-ls() {
  emulate -L zsh
  local current=${AI_PROFILE:-$AI_DEFAULT_PROFILE} profile tool marker
  for profile in ${(f)"$(_ai_profiles)"}; do
    [[ $profile == $current ]] && marker='*' || marker=' '
    print -r -- "$marker $profile"
    for tool in ${(f)"$(_ai_profile_tools "$profile")"}; do
      print -r -- "    $tool  $(_ai_dir "$profile" "$tool")"
    done
  done
}

# ai-update — update Claude Code, Codex, their plugins and the skills in every profile.
ai-update() {
  sh "$AI_DOTFILES/ai/update.sh" "$@"
}

# ai-doctor — check that every profile matches what the dotfiles declare.
ai-doctor() {
  sh "$AI_DOTFILES/ai/doctor.sh" "$@"
}

_ai_define_shorthands ${(f)"$(_ai_profiles)"}
