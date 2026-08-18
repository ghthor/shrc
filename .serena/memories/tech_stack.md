# Nix toolchain

- Nix flakes with pinned nixpkgs stable, Darwin-specific nixpkgs, unstable nixpkgs, Home Manager, and Serena inputs.
- Home Manager profiles: `x86_64-linux.ghthor` and `aarch64-darwin.willowens` in the main flake.
- Make is used for Home Manager and NixOS wrappers.
- `treefmt` is the repository formatter; do not use `nix fmt` for verification.
