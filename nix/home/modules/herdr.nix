{
  config,
  lib,
  pkgs-unstable,
  ...
}:
{
  options.shrc.herdr.enable = lib.mkEnableOption "Herdr configuration";

  config = lib.mkIf config.shrc.herdr.enable {
    home.packages = [ pkgs-unstable.herdr ];

    home.activation.herdrConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source ${./link_path.sh}

      shrc_link_path \
        "$HOME/src/shrc/nix/home/config/herdr/config.toml" \
        "$HOME/.config/herdr/config.toml"
    '';
  };
}
