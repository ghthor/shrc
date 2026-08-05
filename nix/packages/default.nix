let
  nixpkgs = ../../../nixpkgs;
  pkgs = import nixpkgs {
    config = { };
    overlays = [ ];
  };
in
{
  vim-tabby = pkgs.callPackage ./vim-tabby.nix { };
  tabby = pkgs.callPackage ./tabby.nix { };
  idr-tools = pkgs.callPackage ./idr-tools.nix { };
}
