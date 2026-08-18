# Useful project commands

- From `nix/`: `make home` defaults to a non-mutating Home Manager build.
- From `nix/`: `make home CMD=switch` performs the explicit Home Manager switch.
- Override platform selection for tests: `make -C nix -n home SYSTEM=Darwin` or `SYSTEM=Linux`; unsupported values fail at Makefile parse time.
- Evaluate native Home Manager outputs: `cd nix && nix eval .#homeConfigurations.x86_64-linux.ghthor.activationPackage.drvPath` and the analogous Darwin selector.
