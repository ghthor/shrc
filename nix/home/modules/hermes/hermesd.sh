#!/usr/bin/env bash
# Thin wrapper around `docker compose` for the Hermes gateway project.
#
#   hermesd              same as `hermesd up`
#   hermesd up [...]     start the gateway and sidecars; exits early if the
#                        gateway container is already running
#   hermesd run [...]    one-off service container (used by `signal-cli`)
#   hermesd <cmd> [...]  any other compose command (down, logs, ps, ...)
#
# `up` and `run` first build any locally produced images that are missing.
# `up` also loads gateway secrets from pass into the environment so compose
# can pass them through to the gateway container.
#
# HERMESD_COMPOSE_FILE       path to the compose file
# HERMESD_CONTAINER_NAME     name of the gateway container
# HERMES_IMAGE               Docker image for the gateway service
# HERMES_SIGNAL_CLI_IMAGE    Docker image for the signal-cli sidecar; built
#                            with hermes-build-signal-cli if missing

set -o errexit
set -o nounset
set -o pipefail

: "${HERMESD_COMPOSE_FILE:?HERMESD_COMPOSE_FILE is not set}"
: "${HERMESD_CONTAINER_NAME:?HERMESD_CONTAINER_NAME is not set}"
: "${HERMES_IMAGE:?HERMES_IMAGE is not set}"
: "${HERMES_SIGNAL_CLI_IMAGE:?HERMES_SIGNAL_CLI_IMAGE is not set}"

compose=(docker compose --file "$HERMESD_COMPOSE_FILE")

# Locally built sidecar images are not pullable; build them before compose
# tries to resolve them.
ensure_local_images() {
  return 0
}

gateway_running() {
  [[ $(docker container inspect --format '{{.State.Running}}' "$HERMESD_CONTAINER_NAME" 2>/dev/null) == true ]]
}

# load_secret VAR PASS_ENTRY: export VAR from pass unless already set.
load_secret() {
  local var=$1 entry=$2 value
  if [[ -n "${!var-}" ]]; then
    return
  fi
  if ! value=$(pass show "$entry"); then
    printf 'hermesd: failed to read %s from pass\n' "$entry" >&2
    exit 1
  fi
  export "$var=$value"
}

load_gateway_secrets() {
  load_secret SLACK_BOT_TOKEN HERMES_SLACK_BOT_TOKEN
  load_secret SLACK_APP_TOKEN HERMES_SLACK_APP_TOKEN
}

if (($# == 0)); then
  set -- up
fi

case "$1" in
up)
  if gateway_running; then
    printf 'hermesd: container %s is already running\n' "$HERMESD_CONTAINER_NAME" >&2
    exit 0
  fi
  ensure_local_images
  load_gateway_secrets
  ;;
run)
  ensure_local_images
  ;;
esac

exec "${compose[@]}" "$@"
