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

# Returns the current git branch (returns nothing if not a git repository)
parse_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

parse_git_dirty() {
  [[ $(git status 2>/dev/null | tail -n1) != "nothing to commit, working tree clean" ]] && echo "±"
}

# Returns the current ruby version.
parse_ruby_version() {
  if (which ruby | grep -q ruby); then
    ruby -v | cut -d ' ' -f2
  fi
}

# Set the terminal title string
# Looks like this:
#     user@hostname: ~/current/working/directory
#
# Set the prompt string (PS1)
# Looks like this:
#     user@hostname ~/current/working/directory [master|1.8.7]$

# (Prompt strings need '\['s around colors.)
function set_ps1() {
  term_title_str="\[\033]0;\u@\h: \w\007\]"
  user_str="\[$_usr_col\]\u\[$_hst_col\]@\h\[$_txt_col\]"
  dir_str="\[$_cwd_col\]\w"

  git_branch=$(parse_git_branch)
  git_dirty=$(parse_git_dirty)
  git_str="\[$_git_col\]$git_branch\[$_wrn_col\]$git_dirty"

  if [ -n "$GOPATH" ]; then
    gopath_str="$(basename $GOPATH)"
  else
    unset gopath_str
  fi

  # Git & Gopath
  if [ -n "$git_branch" ] && [ -n "$gopath_str" ]; then
    env_str=" \[$_env_col\][$git_str\[$_env_col\]]($gopath_str)"
  # Just Git
  elif [ -n "$git_branch" ]; then
    env_str=" \[$_env_col\][$git_str\[$_env_col\]]"
  # Just Gopath
  elif [ -n "$gopath_str" ]; then
    env_str=" \[$_env_col\]($gopath_str)"
  else
    unset env_str
  fi

  # <date>
  # <exitcode> <username>@<hostname> <pwd> [<git branch>](<gopath>)
  # $
  case $TERM in
  screen* | xterm* | tmux* | alacritty)
    PS1="$term_title_str"
    PS1+="\$(EXIT="\$?"; date; if [ \$EXIT == 0 ]; then echo \"$_grn_col\$EXIT\"; else echo \"$_wrn_col\$EXIT\"; fi) "
    PS1+="$user_str $dir_str$env_str\n\[$_sep_col\]$ \[$_txt_col\]"
    ;;
  *)
    PS1='[\u@\h \W]\$ '
    ;;
  esac
}

# Set custom prompt
PROMPT_COMMAND=''

function set_term_title() {
  local -r wd=$(pwd | sed "s_${HOME}_~_")
  echo -ne "\033]0;$(whoami)@$(hostname): ${wd}\007"
}

starship_precmd_user_func="set_term_title"

# Set GREP highlight color
export GREP_COLOR='1;32'

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
if [ ! "$(uname)" = "Darwin" ]; then
  if [ "${SSH_AGENT_PID:-0}" -ne $$ ]; then
    unset SSH_AGENT_PID
  fi
  if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  fi
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

source_file "$HOME/.bash_completion"
source_file "$HOME/.bash_funcs"
source_file "$HOME/.bash_aliases"

# Setup zoxide autojumper
eval "$(zoxide init bash)"
eval "$(starship init bash)" # starship must be last to modify PROMPT_COMMAND

source_file "$HOME/.fzf.bash"
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
  complete -C /home/ghthor/go/bin/aws-sso aws-sso
fi
# END_AWS_SSO_CLI
