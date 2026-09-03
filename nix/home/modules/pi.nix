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
        --run 'if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then cd "$git_root"; fi' \
        --run '
          pi_path="${pkgs-unstable.pi-coding-agent}/bin/pi"
          for arg in "$@"; do
            case "$arg" in
              install | remove | uninstall | update | list | config | --help | -h)
                exec "$pi_path" "$@"
                ;;
            esac
          done
        ' \
        ${lib.optionalString config.shrc.pi.openrouter.enable "--run 'export OPENROUTER_API_KEY=$(pass show openrouter-key)'"}
    '';
  };
in
{
  options.shrc.pi = {
    enable = lib.mkEnableOption "Pi coding agent configuration";
    openrouter.enable = lib.mkEnableOption "OpenRouter API key for Pi";
  };

  config = lib.mkIf config.shrc.pi.enable {
    home.packages = [ pi-coding-agent-wrapped ];

    home.activation.piMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source ${./link_path.sh}

      shrc_link_path \
        "$HOME/src/shrc/nix/home/config/mcp" \
        "$HOME/.config/mcp"
    '';

    home.activation.piExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source ${./link_path.sh}

      shrc_link_path \
        "$HOME/src/shrc/nix/home/config/pi/agent/extensions" \
        "$HOME/.pi/agent/extensions"
    '';

    home.activation.piSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source ${./link_path.sh}

      shrc_link_path \
        "$HOME/src/shrc/nix/home/config/agents/skills" \
        "$HOME/.agents/skills"
    '';

    home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source ${./link_path.sh}

      shrc_link_path \
        "$HOME/src/shrc/nix/home/config/pi/agent/settings.json" \
        "$HOME/.pi/agent/settings.json"
    '';
  };
}
