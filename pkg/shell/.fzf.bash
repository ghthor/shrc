#!/usr/bin/env bash

if [ "$(uname)" = "Darwin" ]; then
  # Auto-completion &&
  # key bindings
  # ------------
  [[ $- == *i* ]] &&
    source $(find /opt/homebrew/Cellar/fzf -name key-bindings.bash) &&
    source $(find /opt/homebrew/Cellar/fzf -name completion.bash) 2>/dev/null

elif command -v fzf-share >/dev/null; then
  source "$(fzf-share)/key-bindings.bash"
  source "$(fzf-share)/completion.bash"
else
  [[ -e /usr/share/fzf/completion.bash ]] &&
    source /usr/share/fzf/completion.bash
  [[ -e /usr/share/fzf/key-bindings.bash ]] &&
    source /usr/share/fzf/key-bindings.bash
fi
