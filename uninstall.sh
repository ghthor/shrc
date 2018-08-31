#!/bin/sh

cd ..
stow -D -t ~/ --ignore=.git/ --ignore=install.sh bashrc/
