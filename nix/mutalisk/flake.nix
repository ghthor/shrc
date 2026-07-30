{
  description = "ghthor's dotfiles";
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

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # In this context, outputs are mostly about getting home-manager what it
  # needs since it will be the one using the flake
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-darwin,
      nixpkgs-unstable,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "copilot.vim"

              # Bunch of repos w/o licenses are now marked as unfree in nixpkgs
              "vim-addon-mw-utils"
              "vim-git"
            ];
        };
      };
      pkgs-darwin = import nixpkgs-darwin {
        inherit system;
        config = {
          allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
            ];
        };
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "graphite-cli"
              "graphite-cli-unwrapped"
            ];
        };
      };

      NIX_PATH = "nixpkgs=${nixpkgs.outPath}:nixpkgs-darwin=${nixpkgs-darwin.outPath}:nixpkgs-unstable=${nixpkgs-unstable.outPath}";

    in
    {
      formatter.${system} = pkgs-unstable.nixfmt-rfc-style;
      homeConfigurations = {
        "willowens" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit pkgs-unstable pkgs-darwin NIX_PATH; };
          modules = [ ./home.nix ];
        };
      };

      apps.${system} = {
        home-manager = {
          type = "app";
          program = "${home-manager.packages.${system}.default}/bin/home-manager";
        };
      };
    };
}
