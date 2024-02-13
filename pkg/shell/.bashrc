#
# ~/.bashrc
#

export PROJ=$HOME/proj
export EDITOR=vim
export CLICOLOR=""
export STARSHIP_CONFIG=~/.starship.toml

# export WINEPREFIX=$HOME/.wine32
# export WINEARCH=win32
export WINEPREFIX=$HOME/.wine64

export BASH_COMP_DEBUG_FILE=/tmp/bash_comp_debug

# Fix TERM variable
if [ "$TERM" == "xterm" ]; then
  TERM=xterm-256color
fi

# Fix OSX locale
if [ "$(uname)" = "Darwin" ]; then
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
fi

# src: https://unix.stackexchange.com/a/217629
pathmunge() {
  if [ -d "$1" ]; then
    if ! echo "$PATH" | grep -Eq "(^|:)$1($|:)"; then
      if [ "$2" = "after" ]; then
        PATH="$PATH:$1"
      else
        PATH="$1:$PATH"
      fi
    fi
  fi
}

if [ -d "/opt/homebrew/bin" ]; then
  pathmunge "/opt/homebrew/bin"
fi

binPaths=(
  "$HOME/.local/bin"
  "$GOPATH/bin"
  "$GOROOT/bin"
  "$HOME/go/bin"
  "$HOME/bin"
  "$HOME/.cargo/bin"
)
#"$(ruby -e 'print Gem.user_dir')/bin"

for dir in "${binPaths[@]}"; do
  pathmunge "$dir"
done

export XDG_CACHE_HOME="$HOME/.cache"

export TF_PLUGIN_CACHE_DIR="$XDG_CACHE_HOME/hashicorp/terraform-plugin"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# -------------------------------------------------------
# Prompt / Xterm
# -------------------------------------------------------

# Prompt colors
_txt_col="\e[00m"    # Std text (white)
_bld_col="\e[01;37m" # Bold text (white)
_grn_col="\e[0;32m"  # Green

_wrn_col="\e[01;31m" # Warning
_sep_col=$_txt_col   # Separators
_usr_col="\e[01;32m" # Username
_cwd_col=$_txt_col   # Current directory
_hst_col=$_grn_col   # Host
_env_col="\e[0;36m"  # Prompt environment
_git_col="\e[01;36m" # Git branch

# Set custom prompt
PROMPT_COMMAND=''

function set_term_title() {
  local -r wd=$(pwd | sed "s_${HOME}_~_")
  echo -ne "\033]0;$(whoami)@$(hostname): ${wd}\007"
  export STARSHIP_CMD_STATUS
}

starship_precmd_user_func="set_term_title"

# Set GREP highlight color
export GREP_COLORS='mt=1;32'

# -------------------------------------------------------
# Config: Bash History
# -------------------------------------------------------

# Eternal bash history.
# ---------------------
# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
export HISTCONTROL=ignorespace
export HISTFILESIZE
export HISTSIZE
export HISTTIMEFORMAT="[%F %T] "
# Change the file location because certain bash sessions truncate .bash_history file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.bash_eternal_history
# Force prompt to write history after every command.
# http://superuser.com/questions/20900/bash-history-loss
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

shopt -s histappend

# -------------------------------------------------------
# GPG & SSH Agent
# -------------------------------------------------------
if [ "$(uname)" = "Darwin" ]; then
  # Src: https://github.com/herlo/ssh-gpg-smartcard-config/blob/master/macOS.md
  # Start gpg-agent if it's not running
  if [ -z "$(pidof gpg-agent 2>/dev/null)" ]; then
    gpg-agent --homedir $HOME/.gnupg --daemon --sh --enable-ssh-support >$HOME/.gnupg/env
  fi
  # Import various environment variables from the agent.
  until [ -f "$HOME/.gnupg/env" ]; do
    source $HOME/.gnupg/env
  done
fi

if [ "${SSH_AGENT_PID:-0}" -ne $$ ]; then
  unset SSH_AGENT_PID
fi
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi

# -------------------------------------------------------
# GPG Pinentry use correct TTY
# -------------------------------------------------------
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

function source_file() {
  if [ -f "$1" ]; then
    source "$1"
  fi
}

# TODO(will): replace with shell.nix bash
# source_file "/opt/homebrew/etc/profile.d/bash_completion.sh"

if [ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
fi

source_file "$HOME/.bash_completion"
source_file "$HOME/.bash_funcs"
source_file "$HOME/.bash_aliases"

# Setup zoxide autojumper
eval "$(zoxide init bash)"
eval "$(starship init bash)" # starship must be last to modify PROMPT_COMMAND
if [ -x "$(command -v direnv 2>/dev/null)" ]; then
  eval "$(direnv hook bash)"
fi

source_file "$HOME/.fzf.bash"

# SCM_Breeze doesn't trigger the dynamic loading of the git completions file
# but depends on function definitions within the git completion script to be
# sourced. So we do that explicitly instead of relying on bash to lazy load
source_file "/etc/profiles/per-user/ghthor/share/bash-completion/completions/git"
source_file "$HOME/.scm_breeze/scm_breeze.sh"

set -o vi

# BEGIN_AWS_SSO_CLI
__aws_sso_profile_complete() {
  COMPREPLY=()
  local _args=${AWS_SSO_HELPER_ARGS:- -L error --no-config-check}
  local cur
  _get_comp_words_by_ref -n : cur

  COMPREPLY=($(compgen -W '$(/home/ghthor/go/bin/aws-sso $_args list --csv -P "Profile=$cur" Profile)' -- ""))

  __ltrim_colon_completions "$cur"
}

aws-sso-profile() {
  local _args=${AWS_SSO_HELPER_ARGS:- -L error --no-config-check}
  if [ -n "$AWS_PROFILE" ]; then
    echo "Unable to assume a role while AWS_PROFILE is set"
    return 1
  fi
  eval $(/home/ghthor/go/bin/aws-sso $_args eval -p "$1")
  if [ "$AWS_SSO_PROFILE" != "$1" ]; then
    return 1
  fi
}

aws-sso-clear() {
  local _args=${AWS_SSO_HELPER_ARGS:- -L error --no-config-check}
  if [ -z "$AWS_SSO_PROFILE" ]; then
    echo "AWS_SSO_PROFILE is not set"
    return 1
  fi
  eval $(aws-sso eval $_args -c)
}

if command -v aws-sso 2>/dev/null; then
  complete -F __aws_sso_profile_complete aws-sso-profile
  complete -C $(command -v aws-sso) aws-sso
fi
# END_AWS_SSO_CLI

for hashi in nomad consul vault terraform; do
  if ! command -v $hashi; then
    continue
  fi
  if [ -x "$(command -v $hashi)" ]; then
    complete -C "$(command -v $hashi)" $hashi
  fi
done
