{
  config,
  lib,
  pkgs,
  serena,
  ...
}:
let
  claude-code-wrapped = pkgs.symlinkJoin {
    name = "claude-code";
    paths = [ pkgs.claude-code ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --set ANTHROPIC_BASE_URL "https://openrouter.ai/api" \
        --set ANTHROPIC_API_KEY "" \
        --set ANTHROPIC_DEFAULT_SONNET_MODEL "openai/gpt-5.6-luna" \
        --set ANTHROPIC_DEFAULT_HAIKU_MODEL "openai/gpt-5.6-luna" \
        --set ANTHROPIC_DEFAULT_OPUS_MODEL "anthropic/claude-sonnet-5" \
        --run 'export ANTHROPIC_AUTH_TOKEN=$(pass show openrouter-key)' \
        --run 'set -- --system-prompt "$(serena prompts print-cc-system-prompt-override)" "$@"'
    '';
  };

  claude-code-bedrock-wrapped = pkgs.symlinkJoin {
    name = "claude-code-bedrock";
    paths = [ pkgs.claude-code ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/claude
      makeWrapper ${pkgs.claude-code}/bin/claude $out/bin/claude-bedrock \
        --set CLAUDE_CODE_USE_BEDROCK 1 \
        --set ANTHROPIC_DEFAULT_SONNET_MODEL "us.anthropic.claude-sonnet-4-6" \
        --set ANTHROPIC_DEFAULT_HAIKU_MODEL "us.anthropic.claude-haiku-4-5-20251001-v1:0" \
        --set ANTHROPIC_DEFAULT_OPUS_MODEL "" \
        --run 'set -- --system-prompt "$(serena prompts print-cc-system-prompt-override)" "$@"'
    '';
  };
in
{
  options.shrc.claude.enable = lib.mkEnableOption "Claude Code configuration";

  config = lib.mkIf config.shrc.claude.enable {
    home.packages = [ claude-code-bedrock-wrapped ];

    programs.claude-code = {
      enable = true;
      package = claude-code-wrapped;
    };

    home.activation.claudeStatusline = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.claude"
      run ln -sfn "$HOME/src/shrc/nix/home/config/claude/statusline-command.py" "$HOME/.claude/statusline-command.py"
      run ln -sfn "$HOME/src/shrc/nix/home/config/claude/settings.json" "$HOME/.claude/settings.json"
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
