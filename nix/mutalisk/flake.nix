{
  description = "ghthor's dotfiles";
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/26d499fc9f1d567283d5d56fcf367edd815dba1d";
    };
    nixpkgs-darwin = {
      url = "github:NixOS/nixpkgs/300cf356fb3aca28d3d73bfd0276ddf6b21dd0c2";
    };
    nixpkgs-unstable = {
      url = "path:/Users/willowens/src/nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-24.11";
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
        inherit (home-manager) lib;
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
