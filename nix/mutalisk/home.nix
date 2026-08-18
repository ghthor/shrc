{
  lib,
  pkgs,
  pkgs-unstable,
  NIX_PATH,
  ...
}:
let
  homeDirectory = "/Users/willowens";
  username = "willowens";

  brewPackages = [
    "amethyst"
    "thaw"
    "font-hack-nerd-font"
    "ghostty"
    "gnupg"
    "kitty" # needs brew install for Kitty.app
    "orbstack"
    "pinentry"
    "pinentry-mac"
    "stats"
    "syncthing"
    "syncthing-app"
    "vim"
    "vlc"
  ];

  packages = with pkgs; [
    (pkgs.writeShellApplication {
      name = "brew_install_stdenv";
      text = ''
        brew install ${builtins.concatStringsSep " " brewPackages}
      '';
    })

    pkgs-unstable.graphite-cli

    vimPlugins.coc-nvim

    pkgs-unstable.amazon-ecr-credential-helper

  ];

  gpg-pinentry = "/opt/homebrew/bin/pinentry-mac";
  gpg-agent-conf = {
    text = ''
      default-cache-ttl 600
      max-cache-ttl 7200
      enable-ssh-support
      extra-socket $HOME/.gnupg/S.gpg-agent.extra
      debug-level none
      # debug-pinentry
      log-file $HOME/.gnupg/gpg-agent.log
      pinentry-program ${gpg-pinentry}
    '';
    target = ".gnupg/gpg-agent.conf";
  };
in
{
  imports = [
    ../home/modules/nix-delete-home-generations.nix
    ../home/modules/common.nix
    ../home/modules/vimrc.nix
    ../home/modules/herdr.nix
    ../home/modules/aws-sso-cli.nix
    ../home/modules/pi.nix
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    inherit NIX_PATH;
  };
  shrc.common.packages = packages;
  shrc.herdr.enable = true;
  shrc.aws-sso-cli.enable = true;
  shrc.pi.enable = true;
  shrc.nix-delete-home-generations.enable = true;

  home.file."gpg-agent.conf" = gpg-agent-conf;

  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    shell = "${pkgs.bash}/bin/bash";
    plugins = [ pkgs.tmuxPlugins.cpu ];
  };
  home.sessionVariables.TMUX_XPANES_EXEC = "tmux -2"; # force tmux from xpanes to be 256color

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    dotDir = homeDirectory;
    initContent =
      let
        initExtra = lib.mkOrder 1000 (builtins.readFile ./zshrc);
      in
      lib.mkMerge [
        initExtra
      ];
  };

  home = {
    stateVersion = "23.11";
    inherit username;
    inherit homeDirectory;
  };
}
