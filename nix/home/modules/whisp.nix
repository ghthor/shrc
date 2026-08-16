{
  config,
  lib,
  pkgs,
  ...
}:
let
  whisperCppVulkan = pkgs.whisper-cpp.override { vulkanSupport = true; };

  whisperModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
    hash = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
  };

  whisp = pkgs.writeShellScriptBin "whisp" ''
    set -euo pipefail

    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/tmp}"
    STATE_DIR="$RUNTIME_DIR/whisp"
    PID_FILE="$STATE_DIR/recorder.pid"
    AUDIO_FILE="$STATE_DIR/recording.wav"
    OUTPUT_FILE="$STATE_DIR/recording"
    STATE_FILE="$STATE_DIR/state"

    mkdir -p "$STATE_DIR"

    set_state() {
      if [ -n "''${1:-}" ]; then
        printf '%s' "$1" > "$STATE_FILE"
      else
        rm -f "$STATE_FILE"
      fi
    }

    fail() {
      set_state ""
      rm -f "$PID_FILE" "$AUDIO_FILE" "$OUTPUT_FILE.txt"
      ${pkgs.libnotify}/bin/notify-send -a "whisp" -u critical "Error" "$1"
      exit 1
    }

    if [ -f "$PID_FILE" ] && PW_PID=$(cat "$PID_FILE") && kill -0 "$PW_PID" 2>/dev/null; then
      kill "$PW_PID" 2>/dev/null || true
      wait "$PW_PID" 2>/dev/null || true
      rm -f "$PID_FILE"

      if [ ! -s "$AUDIO_FILE" ]; then
        fail "No audio recorded."
      fi

      set_state "transcribing"

      THREADS=$(${pkgs.coreutils}/bin/nproc)
      if ! ${whisperCppVulkan}/bin/whisper-cli \
        --model ${whisperModel} \
        --file "$AUDIO_FILE" \
        --output-txt \
        --output-file "$OUTPUT_FILE" \
        --language en \
        --no-timestamps \
        --no-prints \
        --threads "$THREADS" >/dev/null 2>&1; then
        fail "Transcription failed."
      fi

      TEXT=$(cat "$OUTPUT_FILE.txt" 2>/dev/null || true)
      rm -f "$AUDIO_FILE" "$OUTPUT_FILE.txt"
      set_state ""

      if [ -z "$TEXT" ]; then
        fail "Transcription produced no output."
      fi

      printf '%s' "$TEXT" | ${pkgs.xclip}/bin/xclip -selection clipboard
      ${pkgs.xdotool}/bin/xdotool type --delay 1 -- "$TEXT"
      exit 0
    fi

    rm -f "$PID_FILE"

    ${pkgs.pipewire}/bin/pw-cat \
      --record \
      --format=s16 \
      --rate=16000 \
      --channels=1 \
      "$AUDIO_FILE" >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    set_state "recording"
  '';
in
{
  options.shrc.whisp.enable = lib.mkEnableOption "Whisp local voice-to-text transcription";

  config = lib.mkIf config.shrc.whisp.enable {
    home.packages = [ whisp ];
  };
}
