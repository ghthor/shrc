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

    xinput
  ];

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
    ./modules/flake-nixpkgs.nix
    ./modules/herdr.nix
    ./modules/aws-sso-cli.nix
    ./modules/nix-delete-generations.nix
    ./modules/nix-delete-home-generations.nix
    ./modules/lutris.nix
    ./modules/vimrc.nix
    ./modules/pi.nix
    ./modules/claude.nix
    ./modules/whisp.nix
    ./modules/fbterm.nix
    ./modules/zsh.nix
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    inherit NIX_PATH;
  };
  shrc.common.packages = packages;
  shrc.herdr.enable = true;
  shrc.aws-sso-cli.enable = true;
  shrc.pi.enable = true;
  shrc.claude.enable = true;
  shrc.whisp.enable = pkgs.stdenv.isLinux;
  shrc.fbterm.enable = pkgs.stdenv.isLinux;
  shrc.nix-delete-generations.enable = true;
  shrc.nix-delete-home-generations.enable = true;
  shrc.zsh.enable = false;

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
    pointer = 1 2 3 4 5 6 7 8 9 10 11 12
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
