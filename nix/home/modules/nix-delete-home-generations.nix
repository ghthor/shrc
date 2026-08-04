{
  config,
  lib,
  pkgs,
  ...
}:

let
  nix-delete-home-generations = pkgs.writeShellApplication {
    name = "nix-delete-home-generations";
    runtimeInputs = with pkgs; [
      colorized-logs
      fzf
      home-manager
      gnugrep
    ];
    text = builtins.readFile ./nix-delete-home-generations.sh;
  };
in
{
  options.shrc.nix-delete-home-generations.enable = lib.mkEnableOption "Home Manager generation cleanup helper";

  config = lib.mkIf config.shrc.nix-delete-home-generations.enable {
    home.packages = [ nix-delete-home-generations ];
  };
}
