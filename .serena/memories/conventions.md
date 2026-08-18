# Nix conventions

- Keep Linux and Darwin Home Manager entry modules separate when users, home directories, package sets, or services differ.
- Register each Home Manager configuration only under its native system output.
- Pass platform package sets and shared `NIX_PATH`/Serena arguments explicitly through `extraSpecialArgs`.
- Preserve existing profile names and platform-specific behavior during consolidation.
