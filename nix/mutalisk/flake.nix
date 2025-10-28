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
    # https://hydra.nixos.org/jobset/nixos/release-25.05/evals
    nixpkgs = {
      url = "github:NixOS/nixpkgs/fc756aa6f5d3e2e5666efcf865d190701fef150a";
      # url = "nixpkgs/nixos-25.05";
    };
    #### Stable release branch tracking darwin specific builds
    ###### Used if darwin needs specific patches to get better caching/fixes
    # https://hydra.nixos.org/jobset/nixpkgs/nixpkgs-25.05-darwin/evals
    nixpkgs-darwin = {
      url = "github:NixOS/nixpkgs/5c8ff8d6a76ae12f399ce646dba7aea9f0c8e6c4";
      # url = "nixpkgs/nixpkgs-25.05-darwin";
    };
    #### Unstable release branch
    # https://hydra.nixos.org/jobset/nixos/trunk-combined
    nixpkgs-unstable = {
      # https://hydra.nixos.org/eval/1819642#tabs-inputs
      url = "github:NixOS/nixpkgs/6a08e6bb4e46ff7fcbb53d409b253f6bad8a28ce";
      # url = "nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.05";
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
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "copilot.vim" ];
        };
      };
      pkgs-darwin = import nixpkgs-darwin {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ ];
        };
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "graphite-cli" ];
        };
      };

      NIX_PATH = "nixpkgs=${nixpkgs.outPath}:nixpkgs-darwin=${nixpkgs-darwin.outPath}:nixpkgs-unstable=${nixpkgs-unstable.outPath}";
      home = import ./home.nix {
        inherit (nixpkgs) lib;
        hmlib = home-manager.lib;
        inherit pkgs;
        inherit pkgs-darwin;
        inherit pkgs-unstable;
        inherit NIX_PATH;
      };

    in
    {
      formatter.${system} = pkgs-unstable.nixfmt-rfc-style;
      homeConfigurations = {
        "willowens" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ home ];
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
