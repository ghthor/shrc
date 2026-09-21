#!/usr/bin/env bash
# Run signal-cli against the Hermes compose project's signal-cli state.
#
# Usage: signal-cli <signal-cli args...>
#
# Runs a one-off container for the compose `signal-cli` service, so it shares
# the daemon's image, network, and state volume. The image entrypoint already
# passes `--config /var/lib/signal-cli`.

set -o errexit
set -o nounset
set -o pipefail

# Keep compose's container create/start progress out of signal-cli's output.
export COMPOSE_PROGRESS=${COMPOSE_PROGRESS:-quiet}

# Compose allocates a pseudo-TTY itself when attached to a terminal; `-i`
# keeps stdin open so interactive commands (e.g. `link`) work.
exec hermesd run -i --rm signal-cli "$@"
