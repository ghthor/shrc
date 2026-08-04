#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

profile=/nix/var/nix/profiles/system

for command in fzf nix-env readlink; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'nix-delete-generations: required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

sudo_bin=/run/wrappers/bin/sudo
if [[ ! -x "$sudo_bin" ]]; then
  sudo_bin=$(command -v sudo || true)
fi
if [[ -z "$sudo_bin" ]]; then
  printf 'nix-delete-generations: required command not found: sudo\n' >&2
  exit 1
fi

if [[ ! -d "$profile" && ! -L "$profile" ]]; then
  printf 'nix-delete-generations: system profile not found: %s\n' "$profile" >&2
  exit 1
fi

dry_run=false
case "${1-}" in
-n | --dry-run)
  dry_run=true
  shift
  ;;
-h | --help)
  printf 'Usage: nix-delete-generations [-n|--dry-run]\n'
  exit 0
  ;;
esac

if (($# > 0)); then
  printf 'Usage: nix-delete-generations [-n|--dry-run]\n' >&2
  exit 2
fi

declare -a selectable=()
declare -a selected=()
declare -a delete_args=(--profile "$profile" --delete-generations)
declare -A generation_lines=()
declare -A protected=()
declare -A seen=()

current_target=$(readlink -f /run/current-system 2>/dev/null || true)
booted_target=$(readlink -f /run/booted-system 2>/dev/null || true)

generation_list=$("$sudo_bin" nix-env --profile "$profile" --list-generations) || {
  printf 'nix-delete-generations: could not list system generations\n' >&2
  exit 1
}

while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*([0-9]+)[[:space:]] ]] || continue
  generation=${BASH_REMATCH[1]}
  generation_link="$profile-$generation-link"
  generation_target=$(readlink -f "$generation_link" 2>/dev/null || true)
  marker=''
  if [[ -n "$current_target" && "$generation_target" == "$current_target" ]]; then
    marker='CURRENT'
  fi
  if [[ -n "$booted_target" && "$generation_target" == "$booted_target" ]]; then
    [[ -n "$marker" ]] && marker+=' '
    marker+='BOOTED'
  fi
  [[ -n "$marker" ]] && protected["$generation"]="$marker"
  generation_lines["$generation"]=$line
  [[ -n "$marker" ]] && line="$line [$marker]"
  selectable+=("$line")
done <<< "$generation_list"

generation_list=''

if ((${#selectable[@]} == 0)); then
  printf 'nix-delete-generations: no system generations found\n' >&2
  exit 1
fi

if ! selection=$(printf '%s\n' "${selectable[@]}" | fzf --multi \
  --header='CURRENT and BOOTED generations are visible but protected' \
  --prompt='Generations> '); then
  printf 'No generations selected.\n'
  exit 0
fi

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^[[:space:]]*([0-9]+)[[:space:]] ]] || {
    printf 'nix-delete-generations: invalid selection: %s\n' "$line" >&2
    exit 1
  }
  generation=${BASH_REMATCH[1]}
  [[ -n "${generation_lines["$generation"]-}" ]] || {
    printf 'nix-delete-generations: generation was not in the original list: %s\n' "$generation" >&2
    exit 1
  }
  if [[ -n "${protected["$generation"]-}" ]]; then
    printf 'nix-delete-generations: refusing to delete protected generation %s (%s)\n' \
      "$generation" "${protected["$generation"]}" >&2
    exit 1
  fi
  if [[ -z "${seen["$generation"]-}" ]]; then
    seen["$generation"]=1
    selected+=("$generation")
    delete_args+=("$generation")
  fi
done <<<"$selection"

if ((${#selected[@]} == 0)); then
  printf 'No generations selected.\n'
  exit 0
fi

printf 'Selected NixOS generations for deletion:\n'
for generation in "${selected[@]}"; do
  printf '  %s\n' "${generation_lines["$generation"]}"
done
printf '\nWarning: deleting generations removes rollback targets.\n'
printf 'Command: '
printf '%q ' "$sudo_bin" nix-env "${delete_args[@]}"
printf '\n'
if [[ "$dry_run" == true ]]; then
  printf 'Dry run: no generations will be deleted.\n'
  exit 0
fi

read -r -p 'Continue? [y/N] ' answer </dev/tty
if [[ ! "$answer" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
  printf 'Cancelled.\n'
  exit 0
fi


current_target=$(readlink -f /run/current-system 2>/dev/null || true)
booted_target=$(readlink -f /run/booted-system 2>/dev/null || true)
for generation in "${selected[@]}"; do
  generation_target=$(readlink -f "$profile-$generation-link" 2>/dev/null || true)
  if [[ "$generation_target" == "$current_target" || "$generation_target" == "$booted_target" ]]; then
    printf 'nix-delete-generations: generation %s became protected; aborting\n' "$generation" >&2
    exit 1
  fi
done

"$sudo_bin" nix-env "${delete_args[@]}"
