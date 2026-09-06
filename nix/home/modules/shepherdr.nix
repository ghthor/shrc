{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  shepherdr = pkgs-unstable.callPackage ../../packages/shepherdr/package.nix { };
  shepherdr-up = pkgs.writeShellApplication {
    name = "shepherdr-up";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.tailscale
      shepherdr
    ];
    text = ''
      set -euo pipefail

      for argument in "$@"; do
        case "$argument" in
          -no-sign-in|--no-sign-in|-public-origin|--public-origin|-public-origin=*|--public-origin=*)
            echo "shepherdr-up manages protected access with a passkey and does not accept $argument" >&2
            exit 2
            ;;
        esac
      done

      sudo -v

      state_directory="$(${pkgs.coreutils}/bin/mktemp --directory)"
      serve_log="$state_directory/tailscale-serve.log"
      serve_pid=""

      cleanup() {
        status=$?
        trap - EXIT INT TERM
        if [ -n "$serve_pid" ] && kill -0 "$serve_pid" 2>/dev/null; then
          sudo -n kill "$serve_pid" 2>/dev/null || true
          wait "$serve_pid" 2>/dev/null || true
        fi
        rm -rf "$state_directory"
        exit "$status"
      }
      trap cleanup EXIT INT TERM

      # The log is written by the wrapper user; sudo only elevates tailscale.
      # shellcheck disable=SC2024
      sudo -n tailscale serve 8787 >"$serve_log" 2>&1 &
      serve_pid=$!

      public_origin=""
      for _ in $(seq 1 30); do
        public_origin="$(${pkgs.gnugrep}/bin/grep -Eo 'https://[a-z0-9][a-z0-9.-]*(:[0-9]+)?/?' "$serve_log" | ${pkgs.gnused}/bin/sed 's:/$::' | ${pkgs.coreutils}/bin/head -n 1 || true)"
        if [ -n "$public_origin" ]; then
          break
        fi
        if ! kill -0 "$serve_pid" 2>/dev/null; then
          wait "$serve_pid" 2>/dev/null || true
          cat "$serve_log" >&2
          echo "tailscale serve exited before providing a public origin" >&2
          exit 1
        fi
        sleep 1
      done

      if [ -z "$public_origin" ]; then
        cat "$serve_log" >&2
        echo "could not determine the Tailscale public origin" >&2
        exit 1
      fi

      echo "Starting Shepherdr at $public_origin" >&2
      shepherdr -public-origin "$public_origin" "$@"
    '';
  };
in
{
  options.shrc.shepherdr.enable = lib.mkEnableOption "Shepherdr configuration";

  config = lib.mkIf config.shrc.shepherdr.enable {
    home.packages = [
      shepherdr
      shepherdr-up
    ];
  };
}
