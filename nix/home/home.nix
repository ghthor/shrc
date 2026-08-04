{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  NIX_PATH,
  ...
}:
let
  homeDirectory = "/home/ghthor";
  username = "ghthor";

  packages = with pkgs; [
    vim-full
    comma
    docker
    git-absorb

    vscodium
    zeal

    remmina # rdp/vnc client
    vlc
    peek

    claude-code-bedrock-wrapped
  ];

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

  gpg-pinentry = pkgs.pinentry-gtk2;
  gpg-agent-conf = {
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
    enableScDaemon = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    enableBashIntegration = true;
    # sshKeys = [
    #   "0x807409C92CE23033"
    # ];
    pinentry.package = gpg-pinentry;
  };
in
{
  imports = [
    ./modules/common.nix
    ./modules/herdr.nix
    ./modules/nix-delete-generations.nix
    ./modules/nix-delete-home-generations.nix
    ./modules/lutris.nix
    ./modules/vimrc.nix
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    inherit NIX_PATH;
  };
  shrc.common.packages = packages;
  shrc.herdr.enable = true;
  shrc.nix-delete-generations.enable = true;
  shrc.nix-delete-home-generations.enable = true;

  home.activation.claudeStatusline = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.claude"
    run ln -sfn "$HOME/src/shrc/nix/home/config/claude/statusline-command.py" "$HOME/.claude/statusline-command.py"
    run ln -sfn "$HOME/src/shrc/nix/home/config/claude/settings.json" "$HOME/.claude/settings.json"
  '';

  programs.claude-code.package = claude-code-wrapped;

  services.gpg-agent = {
    enable = true;
  }
  // gpg-agent-conf;

  programs.gpg = {
    enable = true;
    mutableKeys = true;
    mutableTrust = true;
    # settings = {
    #   "no-autostart" = "";
    # };
  };

  home.file.".Xmodmap".text = ''
    pointer = 1 3 2 4 5 6 7 8 9 10 11 12
  '';

  services.pasystray.enable = true;

  programs.obs-studio = {
    enable = true;
  };

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.tmux = {
    enable = true;
    prefix = "C-g";
    mouse = true;
    terminal = "tmux-256color";
    plugins = [
      pkgs.tmuxPlugins.catppuccin
      pkgs.tmuxPlugins.cpu
      pkgs.tmuxPlugins."pain-control"
      pkgs.tmuxPlugins.sensible
    ];
  };
  home.sessionVariables.TMUX_XPANES_EXEC = "tmux -2"; # force tmux from xpanes to be 256color

  home = {
    stateVersion = "23.11";
    inherit username;
    inherit homeDirectory;
  };
}
