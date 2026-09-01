{
  description = "ghthor's system flakes";
  inputs = {
    # 1. Check Statuses of channels and hydra before updating
    #   - https://nixos.wiki/wiki/Nix_channels
    #   - https://status.nixos.org/
    # 2. Update links to the eval selected
    # 3. Document if revisions differs from hydra eval
    #   - Ex: slightly newer to pick up a patch

    #### Main stable release branch
    # https://hydra.nixos.org/jobset/nixos/release-26.05/evals
    nixpkgs = {
      # https://hydra.nixos.org/eval/1827033#tabs-inputs
      url = "github:NixOS/nixpkgs/8f0500b9660505dc3cb647775fe9a978a74b5283";
      # url = "nixpkgs/nixos-26.05";
    };

    #### Stable release branch tracking darwin specific builds
    ###### Used if darwin needs specific patches to get better caching/fixes
    # https://hydra.nixos.org/jobset/nixpkgs/nixpkgs-26.05-darwin/evals
    nixpkgs-darwin = {
      # https://hydra.nixos.org/eval/1827053#tabs-inputs
      url = "github:NixOS/nixpkgs/572a2c2b6faebd71246e3162e4217d7ca63a9300";
      # url = "nixpkgs/nixpkgs-26.05-darwin";
    };

    #### Unstable release branch
    # https://hydra.nixos.org/jobset/nixos/unstable
    nixpkgs-unstable = {
      # https://hydra.nixos.org/eval/1827505#tabs-inputs
      url = "github:NixOS/nixpkgs/624af665418d3c65d544145b4d34ad696439570e";
      # url = "nixpkgs/nixos-unstable";
    };

    nixpkgs-claude.url = "github:NixOS/nixpkgs/34ab99075ac4f7e40cf037eef32cb1c360bb85e9";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    serena = {
      url = "github:oraios/serena";
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
      nixpkgs-claude,
      home-manager,
      serena,
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
          pkgs-claude = import nixpkgs-claude {
            inherit system;
            config = nixpkgsConfig;
          };
          pkgs-darwin = import nixpkgs-darwin {
            inherit system;
            config = nixpkgsConfig;
          };
          NIX_PATH = "nixpkgs=${nixpkgs.outPath}:nixpkgs-darwin=${nixpkgs-darwin.outPath}:nixpkgs-unstable=${nixpkgs-unstable.outPath}";

          homeConfiguration =
            lib.optionalAttrs linuxSystem {
              ghthor = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                extraSpecialArgs = {
                  inherit
                    pkgs-unstable
                    pkgs-claude
                    NIX_PATH
                    serena
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
                    pkgs-darwin
                    NIX_PATH
                    serena
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
