{
  description = "ghthor's system flakes";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    # 1. Check Statuses of channels and hydra before updating
    #   - https://nixos.wiki/wiki/Nix_channels
    #   - https://status.nixos.org/
    # 2. Update links to the eval selected
    # 3. Document if revisions differs from hydra eval
    #   - Ex: slightly newer to pick up a patch

    #### Main stable release branch
    # https://hydra.nixos.org/jobset/nixos/release-26.05/evals
    nixpkgs = {
      # https://hydra.nixos.org/eval/1828759#tabs-inputs
      url = "github:NixOS/nixpkgs/a5cc6f2c37bf518436dc8d1c288ccd0c43c2f4c4";
      # url = "nixpkgs/nixos-26.05";
    };

    #### Stable release branch tracking darwin specific builds
    ###### Used if darwin needs specific patches to get better caching/fixes
    # https://hydra.nixos.org/jobset/nixpkgs/nixpkgs-26.05-darwin/evals
    nixpkgs-darwin = {
      # https://hydra.nixos.org/eval/1828730#tabs-inputs
      url = "github:NixOS/nixpkgs/c19db427a1fdfc7591c0b0baeb4665dcef2c61da";
      # url = "nixpkgs/nixpkgs-26.05-darwin";
    };

    #### Unstable release branch
    # https://hydra.nixos.org/jobset/nixos/unstable
    nixpkgs-unstable = {
      # https://hydra.nixos.org/eval/1828722#tabs-inputs
      url = "github:NixOS/nixpkgs/3ed67ec0a4d3c7ab4ae1f04f8ee8df07bfa506a2";
      # url = "nixpkgs/nixos-unstable";
    };

    nixpkgs-pi = {
      url = "github:NixOS/nixpkgs/b1b875982b17dabde9b4a37f3e229e74913e6db3";
    };

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    serena = {
      # Adapt the flake to nixpkgs' deprecation of the stdenv platform predicates.
      # https://github.com/oraios/serena/commit/6d387aa8ec968c08000ff44eef709e810016c1cb
      url = "github:oraios/serena?rev=6d387aa8ec968c08000ff44eef709e810016c1cb";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    treehouse = {
      # v2.3.0, pinned to a newer commit that fixes the flake package build.
      url = "github:ghthor/treehouse?rev=3feda26154e634685a94f9d683a8117b711351b8";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    no-mistakes = {
      url = "github:ghthor/no-mistakes?rev=387ac2a577ffcb496ed3b3a5918b30acf1366d37";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    hermes-agent = {
      # Tracks the branch; the commit is pinned by flake.lock. `nix flake update
      # hermes-agent` moves both the native package and the container build
      # (hermes-build-minimal reads the locked rev) together.
      url = "github:ghthor/hermes-agent/nix/add-container-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      nixpkgs-darwin,
      nixpkgs-unstable,
      nixpkgs-pi,
      home-manager,
      serena,
      treehouse,
      no-mistakes,
      hermes-agent,
      ...
    }@attrs:
    let
      inherit (nixpkgs) lib;

      unfreePredicate =
        pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [
          "copilot.vim"
          # Repositories without licenses are marked unfree in nixpkgs.
          "vim-addon-mw-utils"
          "vim-git"
          "graphite-cli"
          "graphite-cli-unwrapped"
          "claude-code"
        ];
      nixpkgsConfig = {
        allowUnfreePredicate = unfreePredicate;
      };

      homeManagerApp = system: pkgs: {
        type = "app";
        program = toString (
          pkgs.writeShellScript "home-manager" ''
            exec ${home-manager.packages.${system}.home-manager}/bin/home-manager "$@"
          ''
        );
      };

      homeManagerOutputs = flake-utils.lib.eachDefaultSystem (
        system:
        let
          darwinSystem = system == "aarch64-darwin";
          linuxSystem = system == "x86_64-linux";

          pkgs = import nixpkgs {
            inherit system;
            config = nixpkgsConfig;
          };
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config = nixpkgsConfig;
          };
          pkgs-darwin = import nixpkgs-darwin {
            inherit system;
            config = nixpkgsConfig;
          };
          pkgs-pi = import nixpkgs-pi {
            inherit system;
            config = nixpkgsConfig;
          };

          pkgs-claude = pkgs-unstable;
          NIX_PATH = "nixpkgs=${nixpkgs.outPath}:nixpkgs-darwin=${nixpkgs-darwin.outPath}:nixpkgs-unstable=${nixpkgs-unstable.outPath}";

          homeConfiguration =
            lib.optionalAttrs linuxSystem {
              ghthor = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                extraSpecialArgs = {
                  inherit
                    pkgs-unstable
                    pkgs-claude
                    pkgs-pi
                    NIX_PATH
                    serena
                    treehouse
                    no-mistakes
                    hermes-agent
                    ;
                };
                modules = [ ./home/home.nix ];
              };
            }
            // lib.optionalAttrs darwinSystem {
              willowens = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                extraSpecialArgs = {
                  inherit
                    pkgs-unstable
                    pkgs-claude
                    pkgs-pi
                    pkgs-darwin
                    NIX_PATH
                    serena
                    treehouse
                    no-mistakes
                    hermes-agent
                    ;
                };
                modules = [ ./mutalisk/home.nix ];
              };
            };
        in
        {
          formatter = if darwinSystem then pkgs-unstable.nixfmt-rfc-style else pkgs.nixfmt-rfc-style;
          homeConfiguration = homeConfiguration;
          apps.home-manager = homeManagerApp system pkgs;
          apps.nh = {
            type = "app";
            program = "${pkgs.nh}/bin/nh";
          };
        }
      );
    in
    (builtins.removeAttrs homeManagerOutputs [ "homeConfiguration" ])
    // {
      homeConfigurations =
        homeManagerOutputs.homeConfiguration.x86_64-linux
        // homeManagerOutputs.homeConfiguration.aarch64-darwin;

      nixosConfigurations = {
        thornix = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = lib.mkMerge [
            attrs
            { useFlake = true; }
          ];
          modules = [
            ./thornix/configuration.nix
            {
              nix.registry.nixpkgs.flake = nixpkgs;
            }
          ];
        };
        cryptnix = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = lib.mkMerge [
            attrs
            { useFlake = true; }
          ];
          modules = [
            ./cryptnix/configuration.nix
            {
              nix.registry.nixpkgs.flake = nixpkgs;
            }
          ];
        };
        nydus = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = lib.mkMerge [
            attrs
            { useFlake = true; }
          ];
          modules = [
            ./nydus/configuration.nix
            {
              nix.registry.nixpkgs.flake = nixpkgs;
            }
          ];
        };
      };
    };
}
