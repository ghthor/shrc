# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }@attrs:
let
  useFlake = if (builtins.hasAttr "useFlake" attrs) then attrs.useFlake else false;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

    ] ++ lib.optionals useFlake [
      ../modules/syncthing.nix
      ../modules/steam.nix
      attrs.home-manager.nixosModules.default

    ] ++ lib.optionals (!useFlake) [
      ./modules/syncthing.nix
      ./modules/steam.nix
      <home-manager/nixos>
    ];

  # nixpkgs.config.allowUnfreePredicate = pkg:
  #   builtins.elem (lib.getName pkg) [
  #     # Add additional package names here
  #   ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "http://cryptnix.local/"
    ];
    trusted-substituters = [
      "http://cryptnix.local/"
    ];
    trusted-public-keys = [
      "cryptnix.local:cDFJzHTVw96mdDraHDg5pNDpxd7x5Z0yyPeJ99IYmqI="
    ];
  };

  services.nix-serve = {
    enable = true;
    secretKeyFile = "/etc/nixos/nix-serve/cache-priv-key.pem";
    bindAddress = "127.0.0.1";
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "${config.networking.hostName}.local" = {
        locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
      };
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thornix"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkForce "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.defaultSession = "xfce";
  services.xserver.videoDrivers = [ "intel" ];

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable mDNS
  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.addresses = true;
    nssmdns4 = true;
  };

  services.tailscale.enable = true;

  services.resolved = {
    enable = true;
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ghthor = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager"
      "docker"
    ];
    packages = with pkgs; [
      nitrokey-app
      albert
      firefox
      chromium
      aws-sso-cli
      gitFull
      gh
      docker
      docker-buildx
      docker-credential-helpers
      amazon-ecr-credential-helper
      xclip
      barrier
      direnv
      obs-studio
    ];
    openssh.authorizedKeys.keys = [ ];

    shell = pkgs.bashInteractive;
  };
  home-manager.users.ghthor = { pkgs, ... }: {
    home.packages = with pkgs; [
      bashInteractive
      docker
      nodejs_21
      statix

      ruby
      rubyfmt

      vlc
    ];

    xdg.enable = true;

    programs.obs-studio = {
      enable = true;
    };

    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        vim-nix
        jellybeans-vim
        vim-gitgutter
        vim-pathogen
        ctrlp-vim
        # https://dev.to/braybaut/integrate-terraform-language-server-protocol-with-vim-38g
        coc-nvim
        vim-tabby
      ];
      settings = { ignorecase = true; };
      extraConfig = ''
        source $HOME/src/shrc/pkg/vim/.vimrc
      '';
    };

    programs.ssh = {
      enable = true;
      extraConfig = ''
      '';
    };

    programs.kitty = {
      enable = true;
      shellIntegration.enableBashIntegration = true;
      theme = "Jellybeans";
    };
    programs.tmux = {
      enable = true;
      mouse = true;
      terminal = "tmux-256color";
    };
    home.sessionVariables.TMUX_XPANES_EXEC = "tmux -2"; # force tmux from xpanes to be 256color

    programs.readline = {
      enable = true;
      extraConfig = builtins.head (
        lib.optional useFlake (builtins.readFile ../../pkg/shell/.inputrc)
        ++ lib.optional (!useFlake) (builtins.readFile /home/ghthor/src/shrc/pkg/shell/.inputrc)
      );
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
      settings = builtins.head (
        lib.optional useFlake (builtins.fromTOML (builtins.readFile ../../pkg/shell/.starship.toml))
        ++ lib.optional (!useFlake) (builtins.fromTOML (builtins.readFile /home/ghthor/src/shrc/pkg/shell/.starship.toml))
      );
    };
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = false;
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
  };

  programs.vim.defaultEditor = true;

  programs.bash = {
    enableCompletion = true;
  };
  programs.git.enable = true;
  programs.git.package = pkgs.gitFull;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    bashInteractive
    nix-bash-completions

    starship
    fzf
    stow
    zoxide

    htop
    bat
    eza
    screen
    tmux
    tmux-xpanes
    entr
    bc

    jq
    tree
    wget
    ripgrep
    fd
    file

    diff-so-fancy
    gnumake
    go

    ruby
    rubyfmt
    python3

    pass
    pwgen

    pciutils
    usbutils
    lm_sensors

    xorg.xmodmap
    xfce.xfce4-sensors-plugin
    xfce.xfce4-systemload-plugin
    xfce.xfce4-cpugraph-plugin

    winetricks

    docker-buildx
    docker-compose
  ];

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      (nerdfonts.override { fonts = [ "Hack" ]; })
    ];
    fontconfig = {
      useEmbeddedBitmaps = true;
      localConf = ''
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <match target="font">
    <edit mode="assign" name="antialias">
      <bool>true</bool>
    </edit>
    <edit mode="assign" name="embeddedbitmap">
      <bool>false</bool>
    </edit>
    <edit mode="assign" name="hinting">
      <bool>true</bool>
    </edit>
    <edit mode="assign" name="hintstyle">
      <const>hintslight</const>
    </edit>
    <edit mode="assign" name="lcdfilter">
      <const>lcddefault</const>
    </edit>
    <edit mode="assign" name="rgba">
      <const>rgb</const>
    </edit>
  </match>
</fontconfig>
      '';
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    settings = {
      default-cache-ttl = 600;
      max-cache-ttl = 7200;
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = !useFlake;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}

