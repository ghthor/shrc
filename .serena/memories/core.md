# shrc Nix source map

- Nix/home-manager and NixOS configuration live under `nix/`; shared Home Manager modules are under `nix/home/modules/`.
- Main flake entry point: `nix/flake.nix`; Home Manager workflow: `nix/Makefile`.
- Platform-specific Darwin Home Manager assets remain under `nix/mutalisk/`; its standalone flake and Makefile are removed.
- Further guidance: `mem:tech_stack`, `mem:suggested_commands`, and `mem:task_completion`.
