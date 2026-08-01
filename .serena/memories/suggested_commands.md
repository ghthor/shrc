# Useful project commands

- From `nix/`, inspect flake outputs with `nix flake show`.
- Format Nix sources with `nix fmt` (flake formatter resolves to the repository's Nix formatter).
- Evaluate/check the flake with `nix flake check` when dependencies and target platform permit.
- Review edits with `git diff -- nix/home/modules/common.nix` and `git status --short`.
