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
    # https://hydra.nixos.org/jobset/nixos/release-25.11/evals
    nixpkgs = {
      # https://hydra.nixos.org/eval/1823025#tabs-inputs
      url = "github:NixOS/nixpkgs/c217913993d6c6f6805c3b1a3bda5e639adfde6d";
      # url = "nixpkgs/nixos-25.05";
    };

    #### Stable release branch tracking darwin specific builds
    ###### Used if darwin needs specific patches to get better caching/fixes
    # https://hydra.nixos.org/jobset/nixpkgs/nixpkgs-25.11-darwin/evals
    nixpkgs-darwin = {
      # https://hydra.nixos.org/eval/1823102#tabs-inputs
      url = "github:NixOS/nixpkgs/49395877fffda8b2fb49346569d0a7cb41e4dad9";
      # url = "nixpkgs/nixpkgs-25.05-darwin";
    };

    #### Unstable release branch
    # https://hydra.nixos.org/jobset/nixos/trunk-combined
    nixpkgs-unstable = {
      # https://hydra.nixos.org/eval/1823865#tabs-inputs
      url = "github:NixOS/nixpkgs/46db2e09e1d3f113a13c0d7b81e2f221c63b8ce9";
      # url = "nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.11";
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
