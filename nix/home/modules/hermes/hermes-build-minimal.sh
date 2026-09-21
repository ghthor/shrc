#!/usr/bin/env bash
# Build the Hermes container from the ghthor/hermes-agent fork and load it
# into the local Docker daemon.
#
# Usage: hermes-build-minimal [commit-sha]
#
# HERMES_CONTAINER_COMMIT provides the default commit when none is given.

set -o errexit
set -o nounset
set -o pipefail

usage() {
  printf 'Usage: hermes-build-minimal [commit-sha]\n'
}

case "${1-}" in
-h | --help)
  usage
  exit 0
  ;;
esac

if (($# > 1)); then
  usage >&2
  exit 2
fi

commit=${1:-${HERMES_CONTAINER_COMMIT:?HERMES_CONTAINER_COMMIT is not set}}

exec hermes-build-image \
  "github:ghthor/hermes-agent/${commit}#packages.aarch64-linux.container-minimal"
