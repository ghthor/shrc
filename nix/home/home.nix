{
  config,
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

    vscodium
    zeal

    remmina # rdp/vnc client
    vlc
    peek
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
    ./modules/vimrc.nix
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    inherit NIX_PATH;
  };
  shrc.common.packages = packages;

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
    mouse = true;
    terminal = "tmux-256color";
  };
  home.sessionVariables.TMUX_XPANES_EXEC = "tmux -2"; # force tmux from xpanes to be 256color

  home = {
    stateVersion = "23.11";
    inherit username;
    inherit homeDirectory;
  };
}
