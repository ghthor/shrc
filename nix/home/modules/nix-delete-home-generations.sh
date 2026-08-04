#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

for command in ansi2txt fzf home-manager; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'nix-delete-home-generations: required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

dry_run=false
case "${1-}" in
  -n | --dry-run)
    dry_run=true
    shift
    ;;
  -h | --help)
    printf 'Usage: nix-delete-home-generations [-n|--dry-run]\n'
    exit 0
    ;;
esac

if (($# > 0)); then
  printf 'Usage: nix-delete-home-generations [-n|--dry-run]\n' >&2
  exit 2
fi

declare -a selectable=()
declare -a selected=()
declare -a remove_args=()
declare -A generation_lines=()
declare -A seen=()
generation_pattern='^.*:[[:space:]]+id[[:space:]]+([0-9]+)[[:space:]]+->'

generation_list=$(home-manager generations | ansi2txt) || {
  printf 'nix-delete-home-generations: could not list Home Manager generations\n' >&2
  exit 1
}

while IFS= read -r line; do
  [[ "$line" =~ $generation_pattern ]] || continue
  generation=${BASH_REMATCH[1]}
  generation_lines["$generation"]=$line
  if [[ "$line" == *"(current)" ]]; then
    line="$line [CURRENT]"
  fi
  selectable+=("$line")
done <<< "$generation_list"

generation_list=''

if ((${#selectable[@]} == 0)); then
  printf 'nix-delete-home-generations: no Home Manager generations found\n' >&2
  exit 1
fi

if ! selection=$(printf '%s\n' "${selectable[@]}" | fzf --multi \
  --header='CURRENT generation is visible but protected' \
  --prompt='Home Manager generations> '); then
  printf 'No generations selected.\n'
  exit 0
fi

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "$line" =~ $generation_pattern ]] || {
    printf 'nix-delete-home-generations: invalid selection: %s\n' "$line" >&2
    exit 1
  }
  generation=${BASH_REMATCH[1]}
  [[ -n "${generation_lines["$generation"]-}" ]] || {
    printf 'nix-delete-home-generations: generation was not in the original list: %s\n' "$generation" >&2
    exit 1
  }
  if [[ "${generation_lines["$generation"]}" == *"(current)" ]]; then
    printf 'nix-delete-home-generations: refusing to delete current generation %s\n' "$generation" >&2
    exit 1
  fi
  if [[ -z "${seen["$generation"]-}" ]]; then
    seen["$generation"]=1
    selected+=("$generation")
    remove_args+=("$generation")
  fi
done <<< "$selection"

if ((${#selected[@]} == 0)); then
  printf 'No generations selected.\n'
  exit 0
fi

printf 'Selected Home Manager generations for deletion:\n'
for generation in "${selected[@]}"; do
  printf '  %s\n' "${generation_lines["$generation"]}"
done
printf '\nWarning: deleting generations removes rollback targets.\n'
printf 'Command: '
printf '%q ' home-manager remove-generations "${remove_args[@]}"
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


current_line=$(home-manager generations | ansi2txt | grep ' (current)$' || true)
if [[ -z "$current_line" ]]; then
  printf 'nix-delete-home-generations: could not re-check current generation; aborting\n' >&2
  exit 1
fi
current_generation=${current_line##* id }
current_generation=${current_generation%% *}
for generation in "${selected[@]}"; do
  if [[ "$generation" == "$current_generation" ]]; then
    printf 'nix-delete-home-generations: generation %s became current; aborting\n' "$generation" >&2
    exit 1
  fi
done

home-manager remove-generations "${remove_args[@]}"
