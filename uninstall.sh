#!/bin/sh

cd ..
stow -D -t ~/ --ignore=.git/ --ignore=.gitmodules --ignore=.gitignore --ignore=install.sh vimrc/
