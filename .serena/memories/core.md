# shrc Nix source map

- `nix/flake.nix` is the flake entrypoint; outputs home-manager/system configurations.
- Home Manager configuration lives under `nix/home/`; shared user packages/settings are in `nix/home/modules/common.nix`.
- Host-specific NixOS configs are sibling directories under `nix/` (e.g. `thornix/`, `cryptnix/`).
- Package definitions/custom overlays live in `nix/packages/` and related host/module directories.
- Nix formatting uses `nixfmt-tree` in the shared package set; see `mem:suggested_commands` for validation commands.
- Project-specific durable toolchain notes: `mem:tech_stack`; style: `mem:conventions`; completion checks: `mem:task_completion`.
