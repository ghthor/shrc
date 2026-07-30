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

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@attrs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "graphite-cli"
            "graphite-cli-unwrapped"
          ];
      };
      inherit (pkgs) lib;
    in
    {
      formatter.${system} = pkgs.nixfmt-rfc-style;

      homeConfigurations."ghthor" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit pkgs-unstable; };
        modules = [ ./thornix/home.nix ];
      };

      apps.${system}.home = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "hm-switch" ''
            exec ${home-manager.packages.${system}.home-manager}/bin/home-manager \
              switch --flake .#ghthor "$@"
          ''
        );
      };

      nixosConfigurations = {
        thornix = nixpkgs.lib.nixosSystem {
          inherit system;
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
          inherit system;
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
          inherit system;
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
