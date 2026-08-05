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

    home.activation.piExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      pi_agent_dir="$HOME/.pi/agent"
      extensions_path="$pi_agent_dir/extensions"
      extensions_source_path="$HOME/src/shrc/nix/home/config/pi/agent/extensions"

      run test -d "$extensions_source_path"
      run mkdir -p "$pi_agent_dir"

      if [ -L "$extensions_path" ]; then
        if [ "$(readlink -f "$extensions_path")" != "$(readlink -f "$extensions_source_path")" ]; then
          run rm "$extensions_path"
          run ln -s "$extensions_source_path" "$extensions_path"
        fi
      elif [ -e "$extensions_path" ]; then
        echo "Pi extensions directory exists at $extensions_path; review it against $extensions_source_path before activating" >&2
        exit 1
      else
        run ln -s "$extensions_source_path" "$extensions_path"
      fi
    '';

    home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      pi_agent_dir="$HOME/.pi/agent"
      settings_path="$pi_agent_dir/settings.json"
      source_path="$HOME/src/shrc/nix/home/config/pi/agent/settings.json"

      run test -f "$source_path"
      run mkdir -p "$pi_agent_dir"

      if [ -L "$settings_path" ]; then
        if [ "$(readlink -f "$settings_path")" != "$(readlink -f "$source_path")" ]; then
          run rm "$settings_path"
          run ln -s "$source_path" "$settings_path"
        fi
      elif [ -e "$settings_path" ]; then
        if cmp -s "$settings_path" "$source_path"; then
          run rm "$settings_path"
          run ln -s "$source_path" "$settings_path"
        else
          echo "Pi settings file exists at $settings_path; review it against $source_path before activating" >&2
          exit 1
        fi
      else
        run ln -s "$source_path" "$settings_path"
      fi
    '';
  };
}
