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
      config_dir="$HOME/.config/herdr"
      config_file="$config_dir/config.toml"
      source_file="$HOME/src/shrc/nix/home/config/herdr/config.toml"

      run test -f "$source_file"
      run mkdir -p "$config_dir"

      if [ -L "$config_file" ]; then
        if [ "$(readlink -f "$config_file")" != "$(readlink -f "$source_file")" ]; then
          run rm "$config_file"
          run ln -s "$source_file" "$config_file"
        fi
      elif [ -e "$config_file" ]; then
        if [ -e "$source_file" ]; then
          echo "Herdr config exists at $config_file; review it against $source_file before activating" >&2
          exit 1
        fi
        run mv "$config_file" "$source_file"
        run ln -s "$source_file" "$config_file"
      else
        run ln -s "$source_file" "$config_file"
      fi
    '';
  };
}
