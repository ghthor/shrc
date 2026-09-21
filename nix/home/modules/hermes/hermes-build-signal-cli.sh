#!/usr/bin/env bash
# Build the signal-cli sidecar image and load it into the local Docker daemon.
#
# Usage: hermes-build-signal-cli
#
# HERMES_SIGNAL_CLI_IMAGE_NIX   Nix file evaluating to the image derivation
# HERMES_SIGNAL_CLI_IMAGE       expected image reference (name:tag)

set -o errexit
set -o nounset
set -o pipefail

: "${HERMES_SIGNAL_CLI_IMAGE_NIX:?HERMES_SIGNAL_CLI_IMAGE_NIX is not set}"
: "${HERMES_SIGNAL_CLI_IMAGE:?HERMES_SIGNAL_CLI_IMAGE is not set}"

if (($# > 0)); then
  printf 'Usage: hermes-build-signal-cli\n' >&2
  exit 2
fi

printf 'hermes-build-signal-cli: building %s\n' "$HERMES_SIGNAL_CLI_IMAGE" >&2
hermes-build-image --file "$HERMES_SIGNAL_CLI_IMAGE_NIX"

if ! docker image inspect "$HERMES_SIGNAL_CLI_IMAGE" >/dev/null 2>&1; then
  printf 'hermes-build-signal-cli: image %s was not loaded\n' "$HERMES_SIGNAL_CLI_IMAGE" >&2
  exit 1
fi
