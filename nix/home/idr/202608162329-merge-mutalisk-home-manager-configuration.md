<!--
Commented sections (like this) are meant to be explanatory. Feel free to delete them.

To create IDRs without these comments:
- Use the --no-comments flag: idr new "Title" --no-comments
- Or set the environment variable: export IDR_NO_COMMENTS=1
-->

# 2026-08-16: Merge Mutalisk Home Manager Configuration

Owner: Will Owens <ghthor@gmail.com>

## Overview

### Problem Statement

We need to remove having 2 flakes, one for linux & one for osx, and associated
Makefile build/switch wrapping. This can be accomplished by updating the main
flake so that it can build the mutalisk home-manager configuration and by
updating the main Makefile so that it can target the correct home-manager
configuration based on whether the current system is Darwin or not.

### Context

The repository currently has two independent Home Manager flakes:

- `nix/flake.nix` targets `x86_64-linux` and exposes
  `homeConfigurations.ghthor`, using `nix/home/home.nix`.
- `nix/mutalisk/flake.nix` targets `aarch64-darwin` and exposes
  `homeConfigurations.willowens`, using `nix/mutalisk/home.nix`.

The two flakes duplicate their Home Manager, stable nixpkgs, Darwin nixpkgs,
unstable nixpkgs, and Serena inputs. Their lock files are also nearly
identical, although the Serena revision currently differs. The shared modules
have already reduced some configuration duplication, but the platform entry
points and package/configuration setup remain separate.

The current build interfaces are also split. `nix/Makefile` always selects
`ghthor` for its `home` target and invokes an installed `home-manager` binary.
`nix/mutalisk/Makefile` separately guards against non-Darwin systems and uses a
flake-provided Home Manager app for its `switch` and `build` targets. This
requires remembering both the correct directory and the correct wrapper.

The two Home Manager configurations intentionally remain platform-specific.
The Linux configuration contains Linux-only packages and modules such as
Whisp, FbTerm, Lutris, Xmodmap, and pasystray. The Darwin configuration
contains macOS-specific package/bootstrap behavior, GPG pinentry setup, zsh
initialization, and the Darwin Ghostty package. Both configurations use the
shared modules under `nix/home/modules/`. The existing configuration names,
`ghthor` and `willowens`, should remain stable so that the merge does not
silently select a different user's profile.

### Goals

- Make `nix/flake.nix` the single flake entry point for both Home Manager
  configurations.
- Preserve the existing `ghthor` Linux and `willowens` Darwin configuration
  names and their platform-specific behavior.
- Consolidate the duplicated flake inputs and lock state into `nix/flake.lock`.
- Make the main `nix/Makefile` select the Home Manager configuration from the
  current system type and support both `build` and `switch` through the same
  command path.
- Remove the separate mutalisk flake and its build/switch Makefile wrapper.
- Fail safely when the system type is neither Darwin nor the supported Linux
  environment rather than applying the wrong user's Home Manager
  configuration.
- Verify that both Home Manager configurations evaluate, and format the
  resulting Nix and Makefile changes with `treefmt`.

### Non-Goals

- Rewriting the Linux or Darwin Home Manager settings into one completely
  generic module.
- Changing usernames, home directories, Home Manager state versions, package
  selections, or platform-specific behavior except where required by the
  consolidation.
- Merging the NixOS system configurations or changing the existing
  `nixosConfigurations` targets.
- Replacing system-type selection with a general multi-user/profile
  management system.
- Automatically changing the active Home Manager generation during migration;
  the user will explicitly run `build` or `switch`.
- Removing unrelated Darwin assets such as the Ghostty package, zshrc, or
  Tabby launch-agent configuration if they are still used by the retained
  Darwin Home Manager configuration.

### Proposed Solution

Keep the platform-specific Home Manager module currently at
`nix/mutalisk/home.nix`, but instantiate it from the main flake as
`homeConfigurations.willowens` only for the `aarch64-darwin` system, alongside
the existing Linux `ghthor` configuration for `x86_64-linux`. The main flake
will create per-system package sets and special arguments so that the Linux
configuration continues to use `x86_64-linux` packages while the Darwin
configuration uses `aarch64-darwin` packages and its existing allow-unfree
settings. The single flake will become the only source of input and lock
information.

Add a pinned, system-specific Home Manager app to the main flake and update
`nix/Makefile` to invoke it with the selected command and configuration. The
Makefile will select `willowens` on Darwin and `ghthor` on non-Darwin
systems; an unsupported system type will stop with an error. Delete the separate mutalisk flake, lock file, and Makefile after the
merged configuration has been evaluated. Keep
platform-specific files that are still referenced by the Darwin configuration
under version control, moving them only if needed to make their ownership
clear.

## Detailed Design

### Flake outputs and package sets

The main flake will expose the Home Manager configurations only for their
native system types:

```text
homeConfigurations.x86_64-linux.ghthor
homeConfigurations.aarch64-darwin.willowens
apps.x86_64-linux.home-manager
apps.aarch64-darwin.home-manager
```

The exact output nesting may differ if the final flake uses a system-aware
helper, but `willowens` must not be registered for Linux and `ghthor` must not
be registered for Darwin. The Makefile's selector must use the corresponding
system-specific output. Each configuration must receive the same special
arguments it receives today:

- `ghthor`: Linux `pkgs`, Linux `pkgs-unstable`, `NIX_PATH`, and `serena`.
- `willowens`: Darwin `pkgs`, Darwin `pkgs-unstable`, `pkgs-darwin`,
  `NIX_PATH`, and `serena`.

The Darwin package set must preserve the existing allow-unfree predicate from
`nix/mutalisk/flake.nix`. The Linux package set must preserve the existing
stable and unstable package behavior. `NIX_PATH` should be generated from the
single flake's pinned inputs for each configuration.

The existing `nix/home/modules/flake-nixpkgs.nix` reads `nix/flake.lock`, so
removing the second lock file will also establish one authoritative source for
its registry pins. When reconciling the two lock files, use the newer Serena
revision currently present in the mutalisk lock for the merged flake. Both
configurations must be evaluated against that selected result.

The current main flake only declares a Linux formatter and app. The merged
flake should provide the Home Manager app and formatter for each supported
native system. The app should run the Home Manager binary from the pinned Home
Manager input and accept the command and flake selector from the caller rather
than hard-coding `switch` or `ghthor`. The Darwin app must be evaluated from
the `aarch64-darwin` package set so that `nix run .#home-manager` works on the
Mac without attempting to evaluate the Darwin Home Manager configuration as a
Linux output.

### Makefile selection

Use the operating-system name reported by `uname`, with an override for
portable testing if useful:

```make
SYSTEM ?= $(shell uname -s)
```

Select `willowens` and the `aarch64-darwin` output when `SYSTEM` is `Darwin`.
Select `ghthor` and the `x86_64-linux` output otherwise, or fail explicitly
if the implementation chooses to support only the currently known Linux
system. The target should then use one command shape for both platforms,
conceptually:

```make
nix run .#home-manager -- $(CMD) --flake .#$(HOME_CONFIGURATION) --show-trace
```

`CMD` should retain the current default of `build`, so switching remains an
explicit `make home CMD=switch`. The NixOS targets and their existing
`USE_FLAKE` behavior are outside this change.

### File ownership and migration

Retain `nix/mutalisk/home.nix` as the Darwin-specific Home Manager module
unless moving it to `nix/home/` materially simplifies the final layout. Keep
its referenced Darwin assets, including `ghostty-bin.nix` and shell/config
files. Remove the mutalisk-only `flake.nix`, `flake.lock`, Makefile, and lock
synchronization helper once no references remain. Update paths and comments
that still describe mutalisk as an independent flake.

Before deleting the old entry point, evaluate or build each configuration
from its native system. The exact selector should follow the final output
shape; for a system-nested output this is conceptually:

```sh
nix build .#homeConfigurations.x86_64-linux.ghthor.activationPackage
nix build .#homeConfigurations.aarch64-darwin.willowens.activationPackage
```

The important constraint is that the Darwin configuration is registered and
built only under `aarch64-darwin`, rather than being exposed as a cross-system
Linux configuration.

The Darwin build should be performed on the Darwin machine or another
supported Darwin build environment. After the new main Makefile has been
verified, run a non-mutating build through it, then use `CMD=switch` for the
actual migration. Home Manager generation rollback remains the recovery path.

## Cross cutting concerns

### Correctness and safety

System-type selection is a safety boundary because the two configurations
have different users and home directories. The `uname -s` result is the
intentional platform identification rule. The Makefile should expose a
`SYSTEM` override for tests, but the normal invocation must obtain the system
type from the current machine rather than relying on a stale manual value. The
target should print the selected system and Home Manager configuration before
invoking Nix when practical. The selected configuration must also resolve to
the current system's native flake output.

A single lock file reduces input drift, but it also means an input update now
affects both platforms. Lock changes should therefore be evaluated against
both Home Manager configurations. Native builds are preferable because the
package sets include platform-specific packages and a Darwin application
bundle.

### Reproducibility

The flake remains pinned to the existing stable, Darwin-specific, unstable,
Home Manager, and Serena inputs. The merge should not silently update all
inputs; the duplicate lock state should be consolidated and the newer Serena
revision from the mutalisk lock should be intentionally selected. The current
lock file is also read by the Home Manager nixpkgs registry module, so it must
be committed together with the flake changes.

### Security and secrets

This change does not alter secret handling. Existing wrappers continue to read
credentials through `pass`, and no credentials should be added to the flake or
Makefile. The Makefile must quote the flake selector and preserve the existing
`--show-trace` behavior.

### Verification

Run `treefmt` as required by the repository instructions. Evaluate or build
both Home Manager activation packages, test Darwin/Linux selection with
explicit `SYSTEM` overrides, and check that an unsupported system type fails
without running Home Manager. Confirm that no remaining Makefile,
documentation, or module references require the removed mutalisk flake.

## Alternatives considered

### Keep two flakes and synchronize them

Rejected. This preserves the duplicated build interfaces and allows inputs and
shared configuration to drift. The lock files already demonstrate this risk:
they currently differ in the pinned Serena revision. The merged flake will
instead use the slightly newer Serena revision from the mutalisk lock.

### Use one generic Home Manager module with conditionals everywhere

Rejected for this change. The Linux and Darwin entry points have materially
different users, home directories, package sets, shell setup, and services.
Keeping thin platform-specific modules makes those boundaries explicit and
avoids making every setting conditional on `pkgs.stdenv`.

### Require the user to pass the configuration manually

Rejected as the default workflow. It would remove the duplicate flake but
would make it easy to apply the wrong profile for the current platform. The
Makefile should select the profile from the operating-system type while still
allowing an explicit test override. The flake's system-specific registration
provides a second guard against selecting a configuration for the wrong
platform.

### Keep the mutalisk Makefile as a compatibility wrapper

Rejected as the end state. It would leave two build/switch interfaces and
continue requiring users to know which directory to enter. A short migration
period may retain a compatibility redirect, but it should not remain as a
second implementation of the workflow.

## Future plans

- Replace the system-type mapping with a declarative system-to-home-
  configuration table shared by the flake and Makefile, or expose a small
  command that computes the selector from system metadata.
- Add dedicated CI or builder checks for both the Linux and Darwin Home Manager
  activation packages.
- Move all remaining Darwin assets from `nix/mutalisk/` into a clearly named
  platform directory if retaining the historical name becomes confusing.
- Consider a shared `forAllSystems` flake helper once additional systems or
  users are added.

## Other reading

- [Home Manager Flakes](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes)
- [Nix Flakes reference](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake)
- [GNU Make conditional syntax](https://www.gnu.org/software/make/manual/html_node/Conditional-Syntax.html)
- `nix/flake.nix` and `nix/mutalisk/flake.nix` — current duplicated flake
  inputs and outputs.
- `nix/Makefile` and `nix/mutalisk/Makefile` — current split build/switch
  interfaces.
- `nix/home/home.nix` and `nix/mutalisk/home.nix` — current platform-specific
  Home Manager configurations.

## Implementation (ephemeral)

Research findings; implementation complete:

- The main flake now exposes the Linux configuration as
  `homeConfigurations.x86_64-linux.ghthor` and the Darwin configuration as
  `homeConfigurations.aarch64-darwin.willowens`.
- The two lock files had the same root inputs and pinned package inputs, but
  differed in the Serena node revision. The merged `nix/flake.lock` uses the
  newer Serena revision from the mutalisk lock.
- The Darwin-specific `ghostty-bin.nix`, `home.nix`, `tabby.plist`, and `zshrc`
  remain under `nix/mutalisk/` because they are still referenced by the
  retained Darwin configuration.
- The merged Home Manager app is system-specific and passes arguments through
  to the pinned Home Manager executable. The main Makefile selects the native
  configuration from `SYSTEM` and defaults to `CMD=build`.
- `flake-utils.lib.eachDefaultSystem` now generates the system-specific
  formatter, app, and Home Manager outputs without repeating a system output
  declaration in the flake.
- A single merged `unfreePredicate` and `nixpkgsConfig` are applied when
  importing stable, unstable, and Darwin-specific nixpkgs inputs for every
  generated system.
- The top-level Home Manager configuration names remain `ghthor` and
  `willowens`; the Makefile passes the un-nested selector (for example,
  `.#willowens`) to Home Manager.

Implementation checklist:

- [x] Add the Darwin Home Manager configuration to `nix/flake.nix`.
- [x] Instantiate package sets and special arguments for both supported
      systems.
- [x] Reconcile `nix/flake.lock` and remove the duplicate lock file.
- [x] Add the shared/system-specific Home Manager app outputs.
- [x] Update `nix/Makefile` system-type selection and remove the mutalisk
      wrapper.
- [x] Remove obsolete mutalisk flake/build files after checking references.
- [x] Evaluate both Home Manager activation packages.
- [x] Run Darwin/Linux selection tests, the unsupported-system failure test,
      `git diff --check`, and `treefmt`.
- [x] Compare the final diff with this IDR and record factual results here.
- [x] Use `flake-utils` to generate per-system outputs.

Verification notes:

- `make -C nix -n home SYSTEM=Darwin` selects `willowens` and
  `aarch64-darwin`; `SYSTEM=Linux` selects `ghthor` and `x86_64-linux`.
- `make -C nix -n home SYSTEM=FreeBSD` fails during Makefile parsing before
  invoking Home Manager.
- Both native Home Manager activation package derivations evaluate
  successfully.
- `treefmt` and `git diff --check` succeed. A full `nix flake check` reaches
  the repository's existing NixOS assertions but fails on
  `system.copySystemConfiguration is not supported with flakes`; direct Home
  Manager output evaluation succeeds.

