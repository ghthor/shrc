{
  description = "ghthor's dotfiles";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # In this context, outputs are mostly about getting home-manager what it
  # needs since it will be the one using the flake
  outputs = { self, nixpkgs, home-manager, ... }: {
    homeConfigurations = {
      "willowens" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [
          ./home.nix
        ];
      };
    };
  };
}
