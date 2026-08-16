# 2026-08-16: PipeWire Whisper voice-to-text transcription

Owner: Will Owens <ghthor@gmail.com>

## Problem Statement

We need a reliable voice-to-text capability for transcribing spoken audio. Audio should be captured through PipeWire and transcribed locally so that recordings and generated text are not sent to a third-party service.

## Context

Thornix runs PipeWire and an X11 desktop session. The transcription workflow should be user-scoped and managed by Home Manager rather than implemented as a system service in `nix/thornix/configuration.nix`. It is Linux-specific and must not be imported or enabled for the Darwin Home Manager configuration.

`whisper.cpp` provides the `whisper-cli` command used to transcribe audio files. The example workflow uses `pw-cat` to record a 16-bit, mono, 16 kHz WAV file, then invokes `whisper-cli` with a locally available `ggml` model. The model will initially be the pinned `base.en` model fetched with Nix.

The example also integrates with Wayland/Sway through Waybar signals, `wl-clipboard`, and `wtype`. Those parts do not apply to Thornix. The Thornix workflow will use `xclip` for the X11 clipboard and `xdotool` to type the resulting text into the focused application. It will not include Waybar integration or Wayland-only tools.

## Goals

- Create a reusable Linux-only Home Manager module at `nix/home/modules/whisp.nix`.
- Import and enable the module from `nix/home/home.nix` only when `pkgs.stdenv.isLinux` is true.
- Provide a `whisp` command that toggles between recording and transcription.
- Capture audio with PipeWire's `pw-cat` as mono, 16-bit, 16 kHz WAV audio.
- Transcribe the completed recording with `whisper-cli` using a pinned, locally fetched `base.en` model.
- Copy the transcription to the X11 clipboard with `xclip` and type it into the focused window with `xdotool`.
- Keep runtime state and temporary recordings under `XDG_RUNTIME_DIR`, with stale state handled safely.
- Report failures with desktop notifications and clean up temporary files and state.

## Non-Goals

- A system-wide service, persistent HTTP server, or transcription daemon.
- Enabling or evaluating the module on Darwin/macOS.
- Wayland/Sway integration, Waybar status modules, `wl-clipboard`, or `wtype`.
- GPU acceleration as a requirement. The package may be built with Vulkan support as in the example, but the workflow must remain usable with CPU inference.
- Speaker diarization, translation, or a graphical configuration interface.
- Selecting or managing multiple clipboard histories. A clipboard manager may be added in a future change.

## Proposed Solution

Implement a Linux-only Home Manager module named `whisp`. In `nix/home/home.nix`, import `./modules/whisp.nix` and conditionally set `shrc.whisp.enable` using `pkgs.stdenv.isLinux`. The module remains disabled on Darwin; making the import conditional on `pkgs` would introduce module-argument recursion during Home Manager evaluation. The module will define a `whisper-cpp` package override with Vulkan support, fetch the `ggml-base.en.bin` model using `pkgs.fetchurl` and its fixed hash, and install a wrapped `whisp` shell script in the user's Home Manager profile. The model will be immutable in the Nix store rather than downloaded by the runtime script.

The command will keep its PID file, state file, and temporary WAV file in an `XDG_RUNTIME_DIR/whisp` directory. The first invocation starts `pw-cat --record` in the background and records its PID. A later invocation stops that process, waits for the WAV file to be finalized, and runs `whisper-cli` with text output, English language selection, no timestamps, no console output, and a thread count based on `nproc`. The resulting text will be sent to `xclip` and typed into the currently focused X11 window with `xdotool`.

The module will include the required runtime dependencies (`pipewire`, `whisper-cpp`, `coreutils`, `procps`, `libnotify`, `xclip`, and `xdotool`) through the generated script rather than relying on undeclared host packages.

## Detailed Design

### Home Manager module

- Add `nix/home/modules/whisp.nix`.
- Define `options.shrc.whisp.enable` with `lib.mkEnableOption`.
- When enabled, add the generated `whisp` script to `home.packages`.
- Import `./modules/whisp.nix` unconditionally so Home Manager can construct its module graph without evaluating `pkgs` to determine imports.
- Enable `shrc.whisp.enable` only when `pkgs.stdenv.isLinux` is true; on Darwin the module is present but remains disabled.
- Verify both the Linux and Darwin Home Manager configurations evaluate with the conditional module arrangement.

### Recording and state

- Use `${XDG_RUNTIME_DIR:-/tmp}/whisp` for `recorder.pid` and `recording.wav`; use a state file in the same runtime area.
- On start, create the state directory, remove an invalid/stale PID file, launch `pw-cat`, write its PID, and mark the state as `recording`.
- On a subsequent invocation, verify the recorded PID is alive, terminate it, wait for it, and remove the PID file.
- Check that the recording is non-empty before transcription.
- Mark the state as `transcribing` while `whisper-cli` runs, then clear state and remove temporary output on success or failure.
- Use `notify-send` for errors; do not send Waybar refresh signals.

### Transcription and output

Invoke `whisper-cli` with the pinned model and equivalent options to the example:

- `--file` set to the temporary WAV file.
- `--output-txt` and an output prefix in the runtime directory.
- `--language en`.
- `--no-timestamps` and `--no-prints`.
- `--threads` set from `nproc`.

Pipe the generated text to `xclip -selection clipboard` and use `xdotool type` with a small delay to insert it into the focused X11 window. The module should document that `DISPLAY` and X11 authorization must be available to the command, as they normally are when launched from the user's desktop session.

## Cross cutting concerns

- The fixed model hash and Nix package references make the executable and model reproducible.
- Audio and transcription output remain local. Temporary audio is removed after transcription, including failure paths where practical.
- Runtime files are placed in the per-user runtime directory and are not shared system-wide.
- The script must quote paths and transcription text, use `set -euo pipefail`, and avoid treating a stale PID file as an active recording.
- `xdotool type` injects text into whichever X11 window has focus. This is intentional for the current workflow but means the user must focus the target application before stopping the recording.
- Vulkan support should not be assumed to be available at runtime; CPU inference remains the compatibility path. The implementation should verify that the selected nixpkgs package can evaluate with the Vulkan override on the pinned platform.

## Alternatives considered

- `whisper-stream`: rejected as the primary integration because its example uses SDL microphone capture rather than PipeWire and would duplicate audio-device handling.
- `whisper-server`: rejected because this use case does not need a persistent HTTP service; invoking `whisper-cli` directly keeps the design smaller and local.
- `wtype` and `wl-clipboard`: rejected because they are Wayland-specific and Thornix uses X11 for this workflow.
- Hosted transcription services: rejected because audio should remain local.

## Future plans

- Add a clipboard manager so transcriptions remain available after subsequent clipboard changes.
- Add a desktop keybinding or launcher integration for invoking the toggle command.
- Evaluate model size, CPU latency, and transcription quality on Thornix before moving beyond `base.en`.
- Revisit GPU acceleration or a different local backend if CPU latency is insufficient.

## Other reading

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
- [whisper.cpp model documentation](https://github.com/ggml-org/whisper.cpp/blob/master/models/README.md)
- [Nixpkgs whisper-cpp package](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/wh/whisper-cpp/package.nix)

## Implementation (ephemeral)

- Added `nix/home/modules/whisp.nix` with the `shrc.whisp.enable` option and generated `whisp` command.
- The command toggles `pw-cat` recording and `whisper-cli` transcription, then copies output with `xclip` and types it with `xdotool`.
- Added a pinned `base.en` model fetch and a Vulkan-enabled `whisper-cpp` package override; CPU inference remains available at runtime.
- Added the module import and enablement to `nix/home/home.nix` only when `pkgs.stdenv.isLinux` is true.
- The Darwin Home Manager configuration does not import this shared Linux home configuration.
- `treefmt --no-cache` passes.
- The Home Manager activation derivation evaluates with `nix eval .#homeConfigurations.ghthor.activationPackage.drvPath` from `nix/`.
- Full `nix flake check --no-build` remains blocked by the pre-existing flake assertion that `system.copySystemConfiguration` is unsupported with flakes in the Thornix NixOS configuration.
