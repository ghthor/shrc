{ config, lib, pkgs, ... }:

let
  nix-delete-generations = pkgs.writeShellApplication {
    name = "nix-delete-generations";
    runtimeInputs = with pkgs; [
      fzf
      nix
      coreutils
    ];
    text = builtins.readFile ./nix-delete-generations.sh;
  };
in
{
  options.shrc.nix-delete-generations.enable = lib.mkEnableOption "NixOS generation cleanup helper";

  config = lib.mkIf config.shrc.nix-delete-generations.enable {
    home.packages = [ nix-delete-generations ];
  };
}
