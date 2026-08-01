# Nix toolchain

- Declarative Nix flake project using nixpkgs, nixpkgs-unstable, and Home Manager.
- Darwin support is handled through `nixpkgs-darwin`; shared modules branch on `pkgs.stdenv.isDarwin` where needed.
- `serena` is a flake input and its package is installed by the shared Home Manager module.
