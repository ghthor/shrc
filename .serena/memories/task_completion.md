# Completion checks

- For Nix changes, run `treefmt --no-cache` and then `nix flake check` from `nix/` when available.
- At minimum inspect `git diff` and ensure the changed Nix file formats cleanly before reporting completion.
