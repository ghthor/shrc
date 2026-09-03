{
  config,
  lib,
  pkgs,
  pkgs-claude,
  serena,
  ...
}:
let
  claude-openrouter = pkgs.symlinkJoin {
    name = "claude-code-openrouter";
    paths = [ pkgs-claude.claude-code ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/claude
      makeWrapper ${pkgs-claude.claude-code}/bin/claude $out/bin/claude-or \
        --set ANTHROPIC_BASE_URL "https://openrouter.ai/api" \
        --set ANTHROPIC_API_KEY "" \
        --set ANTHROPIC_DEFAULT_SONNET_MODEL "openai/gpt-5.6-luna" \
        --set ANTHROPIC_DEFAULT_HAIKU_MODEL "openai/gpt-5.6-luna" \
        --set ANTHROPIC_DEFAULT_OPUS_MODEL "openai/gpt-5.6-luna" \
        --run 'export ANTHROPIC_AUTH_TOKEN=$(pass show openrouter-key)' \
        --run 'set -- --system-prompt "$(serena prompts print-cc-system-prompt-override)" "$@"'
    '';
  };
in
{
  options.shrc.claude.enable = lib.mkEnableOption "Claude Code configuration";

  config = lib.mkIf config.shrc.claude.enable {
    home.packages = [ claude-openrouter ];

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
