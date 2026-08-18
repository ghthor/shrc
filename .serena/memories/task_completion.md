# Nix completion checks

- Run `treefmt` (or `treefmt --ci`) and `git diff --check`.
- For Home Manager changes, evaluate both native activation package derivation paths.
- Exercise Makefile platform selection with Darwin and Linux overrides and verify an unsupported system fails without invoking Home Manager.
- Check references after removing flake/wrapper files with `rg`.
- Full `nix flake check` may include unrelated NixOS assertions; report those separately from direct Home Manager evaluation.
