#!/usr/bin/env bash
# Run the Hermes agent container.
#
# When launched inside a herdr session (HERDR_SOCKET_PATH is set), the herdr
# unix socket is bridged to TCP with socat so the container can reach it via
# HERDR_SOCKET_TCP=host.docker.internal:<port>.
#
# HERMES_IMAGE selects the Docker image to run. HERMES_NATIVE is the host
# hermes binary; subcommands that must run on the host (`hermes mcp`, which
# is spawned by MCP clients on the host) are routed to it directly. Set
# HERMES_NO_NATIVE=1 to disable that routing and run everything in Docker.

set -o errexit
set -o nounset
set -o pipefail

: "${HERMES_IMAGE:?HERMES_IMAGE is not set}"
: "${HERMES_NATIVE:?HERMES_NATIVE is not set}"

if [[ -z "${HERMES_NO_NATIVE-}" ]]; then
  case "${1-}" in
  mcp)
    exec "$HERMES_NATIVE" "$@"
    ;;
  esac
fi

docker_args=(
  -it --rm
  -e HERDR_PANE_ID
  -e HERDR_ENV
  -e HERDR_TAB_ID
  -e HERDR_WORKSPACE_ID
  -v "$HOME/.hermes:/opt/data"
)

socat_pid=''
cleanup() {
  if [[ -n $socat_pid ]]; then
    # socat forks a child per connection; kill the whole process group so
    # children servicing (possibly half-open) connections go too.
    kill -- "-$socat_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT
# Ensure cleanup also runs if the pane/terminal goes away.
trap 'exit 129' HUP
trap 'exit 143' TERM

# Address on the host that containers can reach. On Darwin the bridge gateway
# lives inside the Docker VM, so bind loopback and rely on the built-in
# host.docker.internal mapping. On Linux the bridge gateway is docker0 on the
# host itself, so bind there (rather than 0.0.0.0) and map the same hostname.
herdr_bind_addr() {
  if [[ $(uname -s) == Darwin ]]; then
    printf '127.0.0.1'
    return
  fi

  local gateway
  gateway=$(docker network inspect bridge | jq -r '.[0].IPAM.Config[0].Gateway')
  if [[ -z $gateway || $gateway == null ]]; then
    printf 'hermes: could not determine docker bridge gateway\n' >&2
    return 1
  fi
  printf '%s' "$gateway"
}

# Pick an unused TCP port on the given address.
free_port() {
  local addr=$1 port
  for ((attempt = 0; attempt < 20; attempt++)); do
    port=$((20000 + RANDOM % 20000))
    if ! (exec 3<>"/dev/tcp/$addr/$port") 2>/dev/null; then
      printf '%s' "$port"
      return
    fi
  done
  printf 'hermes: could not find a free port on %s\n' "$addr" >&2
  return 1
}

if [[ -n "${HERDR_SOCKET_PATH-}" ]]; then
  if [[ ! -S $HERDR_SOCKET_PATH ]]; then
    printf 'hermes: HERDR_SOCKET_PATH is not a socket: %s\n' "$HERDR_SOCKET_PATH" >&2
    exit 1
  fi

  bind_addr=$(herdr_bind_addr)
  port=$(free_port "$bind_addr")

  if [[ $(uname -s) != Darwin ]]; then
    docker_args+=(--add-host=host.docker.internal:host-gateway)
  fi

  # Job control puts the background socat in its own process group so cleanup
  # can kill it and all of its forked children together. -d0 silences the
  # "exiting on signal" warnings that cleanup would otherwise print.
  set -o monitor
  socat -d0 \
    "TCP-LISTEN:$port,bind=$bind_addr,reuseaddr,fork" \
    "UNIX-CONNECT:$HERDR_SOCKET_PATH" &
  socat_pid=$!
  set +o monitor

  docker_args+=(-e "HERDR_SOCKET_TCP=host.docker.internal:$port")
fi

docker run "${docker_args[@]}" "$HERMES_IMAGE" "$@"
