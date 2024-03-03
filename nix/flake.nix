{
  description = "ghthor's system flakes";
  inputs = {
    nixpkgs.url = "path:/home/ghthor/src/nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@attrs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (pkgs) lib;
  in {
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
    };
  };
}
