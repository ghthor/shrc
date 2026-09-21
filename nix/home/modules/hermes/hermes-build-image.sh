#!/usr/bin/env bash
# Build a Nix container image (dockerTools.streamLayeredImage) and load it into
# the local Docker daemon. On Darwin the build runs on the Orb VM.
#
# Usage: hermes-build-image <nix build installable args...>

set -o errexit
set -o nounset
set -o pipefail

if (($# == 0)); then
  printf 'Usage: hermes-build-image <nix build installable args...>\n' >&2
  exit 2
fi

system=$(uname -s)
nix_args=(--no-link --print-out-paths)

if [[ $system == Darwin ]]; then
  nix_args+=(--store ssh-ng://orb --eval-store auto)
fi

out=$(nix build "${nix_args[@]}" "$@")

if [[ $system == Darwin ]]; then
  # The store path is intentionally expanded locally and executed on orb.
  # shellcheck disable=SC2029
  ssh orb "$out"
else
  "$out"
fi | docker load
