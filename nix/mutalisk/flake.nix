{
  description = "ghthor's dotfiles";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "path:/Users/willowens/src/nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # In this context, outputs are mostly about getting home-manager what it
  # needs since it will be the one using the flake
  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "aarch64-darwin";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          ];
        };
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "graphite-cli"
          ];
        };
      };

      NIX_PATH =
        "nixpkgs=${nixpkgs.outPath}:unstable=${nixpkgs-unstable.outPath}";
      home = import ./home.nix {
        inherit pkgs;
        inherit pkgs-unstable;
        inherit NIX_PATH;
      };

    in {
      formatter.${system} = pkgs.nixfmt;
      homeConfigurations = {
        "willowens" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ home ];
        };
      };
    };
}
