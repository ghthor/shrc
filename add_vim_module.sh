#!/usr/bin/env bash

set -euo pipefail

upstream=$(gum input \
  --placeholder=https://github.com/junegunn/fzf.git \
  --prompt="> ")
dir=$(echo "$upstream" | awk -F"/" '{print $NF}')
dir=${dir%%".git"}

name="bundle/$dir"
filepath="pkg/vim/.vim/bundle/$dir"

accept=$(gum input \
  --header="$(echo \$ git submodule add --name "$name" "$upstream" "$filepath")" \
  --prompt="Does this look good (type \"yes\" to continue? " \
  --value=yes)

if [ "$accept" != "yes" ]; then
  exit 1
fi

set -x

git submodule add --name "$name" "$upstream" "$filepath"
