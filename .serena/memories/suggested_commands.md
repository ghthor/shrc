# Useful project commands

- From `nix/`, inspect flake outputs with `nix flake show`.
- Format Nix sources with `treefmt` (use `treefmt --no-cache <paths>` for targeted checks).
- Evaluate/check the flake with `nix flake check` when dependencies and target platform permit.
- Review edits with `git diff -- nix/home/modules/common.nix` and `git status --short`.
