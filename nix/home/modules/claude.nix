{
  config,
  lib,
  pkgs,
  pkgs-claude,
  serena,
  ...
}:
{
  options.shrc.claude.enable = lib.mkEnableOption "Claude Code configuration";

  config = lib.mkIf config.shrc.claude.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs-claude.claude-code;
    };

    home.activation.claudeSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source ${./link_path.sh}

      shrc_link_path \
        "$HOME/src/shrc/nix/home/config/agents/skills" \
        "$HOME/.claude/skills"
    '';

    home.activation.claudeStatusline = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source ${./link_path.sh}

      shrc_link_path \
        "$HOME/src/shrc/nix/home/config/claude/statusline-command.py" \
        "$HOME/.claude/statusline-command.py"

      shrc_link_path \
        "$HOME/src/shrc/nix/home/config/claude/settings.json" \
        "$HOME/.claude/settings.json"
    '';

    home.activation.serenaClaudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Serena looks up Claude Code by name during its setup check.
      export PATH="${config.home.profileDirectory}/bin:$PATH"

      if [[ -f "$HOME/.claude/settings.json" ]] && ${pkgs.jq}/bin/jq -e '.mcpServers.serena' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
        echo "Serena MCP server already configured; skipping setup."
      else
        run ${
          serena.packages.${pkgs.stdenv.hostPlatform.system}.serena
        }/bin/serena setup claude-code || true
      fi
    '';
  };
}
