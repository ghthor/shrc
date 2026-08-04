#!/usr/bin/env bash

# Capture GPG/scdaemon state from a terminal, VT, or tmux pane.
# Run this as the affected user, not through sudo:
#   bash home/gpg-debug.sh |& tee "$HOME/gpg-debug-$(date +%s).log"

set -u

printf '%s\n' '== Session =='
printf 'date: '; date --iso-8601=seconds
printf 'user: %s\n' "${USER:-<unset>}"
printf 'tty: '; tty || true
printf 'TERM: %s\n' "${TERM:-<unset>}"
printf 'GPG_TTY: %s\n' "${GPG_TTY:-<unset>}"
printf 'GNUPGHOME: %s\n' "${GNUPGHOME:-<unset>}"
printf 'XDG_RUNTIME_DIR: %s\n' "${XDG_RUNTIME_DIR:-<unset>}"
printf 'SSH_AUTH_SOCK: %s\n' "${SSH_AUTH_SOCK:-<unset>}"
printf 'DISPLAY: %s\n' "${DISPLAY:-<unset>}"
printf 'WAYLAND_DISPLAY: %s\n' "${WAYLAND_DISPLAY:-<unset>}"
printf '\n'

printf '%s\n' '== GPG directories =='
gpgconf --list-dirs 2>&1 || true
printf '\n'

printf '%s\n' '== Agent and scdaemon processes =='
ps -eo user,pid,ppid,lstart,tty,stat,args \
  | grep -E '[s]cdaemon|[g]pg-agent|[p]cscd|[n]itrokey|[o]pensc' \
  || true
printf '\n'

printf '%s\n' '== Agent protocol =='
gpg-connect-agent 'GETINFO pid' /bye 2>&1 || true
gpg-connect-agent 'GETINFO version' /bye 2>&1 || true
gpg-connect-agent 'GETINFO socket_name' /bye 2>&1 || true
printf '\n'

printf '%s\n' '== Scdaemon protocol =='
gpg-connect-agent 'SCD GETINFO version' /bye 2>&1 || true
gpg-connect-agent 'SCD RESET' /bye 2>&1 || true
gpg-connect-agent 'SCD GETINFO reader_list' /bye 2>&1 || true
gpg-connect-agent 'SCD SERIALNO' /bye 2>&1 || true
printf '\n'

printf '%s\n' '== Card status =='
# This is the decisive reader/card test. It should not invoke pinentry.
gpg --card-status 2>&1 || true
printf '\n'

printf '%s\n' '== Runtime scdaemon options =='
gpgconf --list-options scdaemon 2>&1 || true
printf '\n'

printf '%s\n' '== USB devices =='
lsusb 2>&1 || true
printf '\n'

printf '%s\n' '== Complete traced card sequence =='
{
  set -x
  gpg-connect-agent 'SCD RESET' /bye
  gpg-connect-agent 'SCD GETINFO reader_list' /bye
  gpg-connect-agent 'SCD SERIALNO' /bye
  gpg --card-status
} 2>&1 || true
printf '\n'

printf '%s\n' 'Debug collection complete.'
