#
# ~/.bashrc
#

export PROJ=$HOME/proj
export EDITOR=vim
export CLICOLOR=""

export QMK_ROOT=$PROJ/hid/qmk_firmware
export QMK_CUSTOM=$QMK_ROOT/keyboards/ergodox_ez/keymaps

export WINEPREFIX=$HOME/.wine-dnd/
export WINEARCH=win32

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
  "$HOME/bin/go-dev-tools"
  "$HOME/bin"
)

for dir in "${binPaths[@]}"; do
  pathmunge "$dir"
done

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
  xterm*)
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
PROMPT_COMMAND='set_ps1;'

# Set GREP highlight color
export GREP_COLOR='1;32'

# -------------------------------------------------------
# Config: Bash History
# -------------------------------------------------------

# Eternal bash history.
# ---------------------
# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
export HISTFILESIZE
export HISTSIZE
export HISTTIMEFORMAT="[%F %T] "
# Change the file location because certain bash sessions truncate .bash_history file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.bash_eternal_history
# Force prompt to write history after every command.
# http://superuser.com/questions/20900/bash-history-loss
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

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

export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

# -------------------------------------------------------
# Bash Completion - Homebrew
# -------------------------------------------------------

if [ "$(uname)" = "Darwin" ]; then
  command -v brew 2>&1 >/dev/null &&
    [[ -f $(brew --prefix)/etc/bash_completion ]] &&
    . $(brew --prefix)/etc/bash_completion
fi

# Setup function definitions
if [ -f "$HOME/.bash_funcs" ]; then
  . "$HOME/.bash_funcs"
fi

# Setup alias definitions
if [ -f "$HOME/.bash_aliases" ]; then
  . "$HOME/.bash_aliases"
fi

# Setup nvm
[[ -s "/usr/share/nvm/init-nvm.sh" ]] && . "/usr/share/nvm/init-nvm.sh"

# Setup autojump support
if [ ! "$(uname)" = "Darwin" ]; then
  [[ -s "/usr/share/autojump/autojump.bash" ]] && . "/usr/share/autojump/autojump.bash"
else
  [[ -s "/usr/local/etc/profile.d/autojump.sh" ]] && . "/usr/local/etc/profile.d/autojump.sh"
fi

# Setup fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Setup scm_breeze
[[ -s "$HOME/.scm_breeze/scm_breeze.sh" ]] && . "$HOME/.scm_breeze/scm_breeze.sh"

set -o vi
