{
  description = "ghthor's dotfiles";
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/fc756aa6f5d3e2e5666efcf865d190701fef150a";
    };
    nixpkgs-darwin = {
      url = "github:NixOS/nixpkgs/5c8ff8d6a76ae12f399ce646dba7aea9f0c8e6c4";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/dfb2f12e899db4876308eba6d93455ab7da304cd";
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
