#!/bin/sh
stow -d $HOME/src \
  --ignore=.git/ \
  --ignore=bin/ \
  --ignore=install.sh \
  --ignore=uninstall.sh \
  --ignore=.gitmodules \
  -t $HOME/ \
  shrc
