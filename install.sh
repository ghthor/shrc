#!/bin/sh

cd ..
stow -t ~/ --ignore=.git/ --ignore=.gitmodules --ignore=.gitignore --ignore=install.sh vimrc/
