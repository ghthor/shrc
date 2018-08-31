#!/bin/bash
alias l='ls -l'
alias l..='(cd ..; ls -l)'
alias ll='ls -l'
alias ll..='(cd ..; ll)'
alias lla='ls -l -a'
alias pfind='ps aux | grep $1'
alias vit='vim $HOME/.tmp/temp'
alias vrc='vim $HOME/.vimrc'

alias pyhttp='python3 -m http.server 8000'

# Git Quickies
alias gitexport='git daemon --base-path=$PWD/../ --verbose --export-all'
alias gtree='git-forest --sha -n20'
alias gfresh='g reset --hard HEAD && git clean -f -d'

if [[ $(uname) == "Darwin" ]]; then
  alias xcrmdd='rm -v -rf $HOME/Library/Developer/Xcode/DerivedData/*'
  alias openproj='open *.xcworkspace'
  alias sysupg='brew update && brew upgrade'
else
  # keychain
  alias kch='eval $(keychain --eval --agents ssh -Q --quiet $HOME/.ssh/id_rsa)'
  alias open='xdg-open'
  alias sysupg='yay'
  alias visys='vim /boot/syslinux/syslinux.cfg'
fi

alias cdgopath='cd $GOPATH'
alias entgopath='GOPATH=$(pwd) bash'

# Golang Quickies
#alias godoc='godoc -goroot=/usr/lib/go -http=":6060"'
alias watch-sensors-cli='for ((;;)); do clear; sensors; sleep 1; done'
