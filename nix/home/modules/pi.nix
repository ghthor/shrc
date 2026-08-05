{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  pi-coding-agent-wrapped = pkgs.symlinkJoin {
    name = "pi-coding-agent-openrouter";
    paths = [ pkgs-unstable.pi-coding-agent ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --run 'export OPENROUTER_API_KEY=$(pass show openrouter-key)'
    '';
  };
in
{
  options.shrc.pi.enable = lib.mkEnableOption "Pi coding agent configuration";

  config = lib.mkIf config.shrc.pi.enable {
    home.packages = [ pi-coding-agent-wrapped ];

    home.activation.piMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      config_dir="$HOME/.config"
      config_path="$config_dir/mcp"
      source_path="$HOME/src/shrc/nix/home/config/mcp"

      run test -d "$source_path"
      run mkdir -p "$config_dir"

      if [ -L "$config_path" ]; then
        if [ "$(readlink -f "$config_path")" != "$(readlink -f "$source_path")" ]; then
          run rm "$config_path"
          run ln -s "$source_path" "$config_path"
        fi
      elif [ -e "$config_path" ]; then
        echo "Pi MCP config exists at $config_path; review it against $source_path before activating" >&2
        exit 1
      else
        run ln -s "$source_path" "$config_path"
      fi
    '';
  };
}
