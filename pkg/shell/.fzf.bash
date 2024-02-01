#!/usr/bin/env bash

if [ "$(uname)" = "Darwin" ]; then
  # Setup homebrew fzf
  # ---------
  if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
    export PATH="$PATH:/usr/local/opt/fzf/bin"
  fi

  # Auto-completion &&
  # key bindings
  # ------------
  [[ $- == *i* ]] &&
    source /usr/local/opt/fzf/shell/completion.bash 2>/dev/null &&
    source /usr/local/opt/fzf/shell/key-bindings.bash

elif command -v fzf-share >/dev/null; then
  source "$(fzf-share)/key-bindings.bash"
  source "$(fzf-share)/completion.bash"
else
  [[ -e /usr/share/fzf/completion.bash ]] &&
    source /usr/share/fzf/completion.bash
  [[ -e /usr/share/fzf/key-bindings.bash ]] &&
    source /usr/share/fzf/key-bindings.bash
fi
