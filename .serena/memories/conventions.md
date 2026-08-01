# Nix conventions

- Shared user packages are collected in a `let`-bound `packages-base` list and installed via `home.packages = packages-base ++ config.shrc.common.packages`.
- Prefer `pkgs` for stable packages and explicitly qualify `pkgs-unstable.<name>` for unstable packages.
- Keep package lists grouped by purpose with blank lines; inline comments explain non-obvious package use.
- Platform-specific configuration uses `lib.optionalAttrs pkgs.stdenv.isDarwin` or `lib.mkIf` rather than separate duplicated modules.
