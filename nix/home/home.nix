{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  unfreeConfig =
    pkg:
    builtins.elem (lib.getName pkg) [
      "graphite-cli"
      "graphite-cli-unwrapped"
      "vim-argumentative"
      "vim-addon-mw-utils"
      "vim-git"
      "claude-code"
    ];
in
{
  imports = [ ./modules/vimrc.nix ];

  xdg.enable = true;

  home.username = "ghthor";
  home.homeDirectory = "/home/ghthor";

  home.file.".Xmodmap".text = ''
    pointer = 1 3 2 4 5 6 7 8 9 10 11 12
  '';

  nixpkgs.config.allowUnfreePredicate = unfreeConfig;

  home.packages = with pkgs; [
    vim
    bashInteractive
    comma
    docker

    nodejs_22
    typescript

    statix

    ruby
    # rubyfmt # current broken

    ruff

    vlc
    gum
    stow
    peek

    vscodium
    zeal

    remmina # rdp/vnc client

    pkgs-unstable.herdr

    nixfmt-tree

    pi-coding-agent
  ];

  services.pasystray.enable = true;

  programs.home-manager.enable = true;

  programs.go.enable = true;

  programs.claude-code.enable = true;

  programs.kitty = {
    enable = true;
    shellIntegration.enableBashIntegration = true;
    themeFile = "Jellybeans";
  };

  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    installVimSyntax = true;
    settings = {
      theme = "Jellybeans";
      font-family = "Hack Nerd Font Mono";
    };
  };

  programs.git = {
    enable = true;
  };

  programs.gh = {
    enable = true;
    settings = {
      aliases = {
        co = "pr checkout";
        pv = "pr view";
        pvw = "pr view --web";
      };
      git_protocol = "ssh";
    };
    gitCredentialHelper.enable = true;
  };

  programs.obs-studio = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = false;
        Compression = false;
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = false;
        ForwardAgent = false;
        HashKnownHosts = false;
        ServerAliveCountMax = 3;
        ServerAliveInterval = 0;
        UserKnownHostsFile = "~/.ssh/known_hosts";
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
    enableScDaemon = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    enableBashIntegration = true;
    # sshKeys = [
    #   "0x807409C92CE23033"
    # ];
    pinentry.package = pkgs.pinentry-gtk2;
  };

  programs.gpg = {
    enable = true;
    mutableKeys = true;
    mutableTrust = true;
    # settings = {
    #   "no-autostart" = "";
    # };
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
  };
  home.sessionVariables.TMUX_XPANES_EXEC = "tmux -2"; # force tmux from xpanes to be 256color

  programs.readline = {
    enable = true;
    extraConfig = builtins.readFile ../../pkg/shell/.inputrc;
  };

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # bash eval ordering matters so managing it manually
  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false; # Manually enabled via initExtra
    settings = builtins.fromTOML (builtins.readFile ../../pkg/shell/.starship.toml);
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export BASHRC_HOME_MANAGER=1
      source $HOME/src/shrc/pkg/shell/.bash_noninteractive

      # Avoid running any of the starship/zoxide/direnv sourcing again
      if [ ! -z "$DIRENV_IN_ENVRC" ]; then
        return
      fi
    '';
    initExtra = ''
      source $HOME/src/shrc/pkg/shell/.bash_interactive
      if [[ $TERM != "dumb" ]]; then
        eval "$(zoxide init bash)"
        eval "$(direnv hook bash)"
        eval "$(starship init bash --print-full-init)"
      fi
    '';
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "23.11";
}
