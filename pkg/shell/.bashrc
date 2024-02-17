#
# ~/.bashrc
#
[[ -f ~/src/shrc/pkg/shell/.bash_noninteractive ]] &&
  source ~/src/shrc/pkg/shell/.bash_noninteractive

[[ $- == *i* ]] || return

[[ -f ~/src/shrc/pkg/shell/.bash_interactive ]] &&
  source ~/src/shrc/pkg/shell/.bash_interactive
