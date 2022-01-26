#!/bin/bash
alias l='ls -l'
alias l..='(cd ..; ls -l)'
alias ll='ls -l'
alias ll..='(cd ..; ll)'
alias lla='ls -l -a'
alias pfind='ps aux | grep $1'
alias vit='vim $HOME/.tmp/temp'
alias vrc='vim $HOME/.vimrc'
alias tree='exa -T'

alias jb='jobs'

alias pyhttp='python3 -m http.server 8000'

alias reload_history="history -c && history -r"

# git
alias gitexport='git daemon --base-path=$PWD/../ --verbose --export-all'
alias gfresh='g reset --hard HEAD && git clean -f -d'
alias cdgit='cd "$(git rev-parse --show-toplevel)"'
alias gb-sortdate="git for-each-ref --sort=committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)'"

alias open='xdg-open'

# Pacman helpers
alias yay-orphans='yay -Qtdq'
alias yay-upg-list='yay -Sy && yay -Qyu'

# golang deprecated
#alias godoc='godoc -goroot=/usr/lib/go -http=":6060"'
alias cdgopath='cd $GOPATH'
alias entgopath='GOPATH=$(pwd) bash'
