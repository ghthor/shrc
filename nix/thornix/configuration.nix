# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}@attrs:
let
  useFlake = if (builtins.hasAttr "useFlake" attrs) then attrs.useFlake else false;

  osConfig = config;

  unfreeConfig =
    pkg:
    builtins.elem (lib.getName pkg) [
      # Add additional package names here
      "nomad"

      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"

      "graphite-cli"
      "graphite-cli-unwrapped"

      # Bunch of repos w/o licenses are now marked as unfree in nixpkgs
      "vim-argumentative"
      "vim-addon-mw-utils"
      "vim-git"

      "claude-code"
    ];
in
{
  imports = [
    ./hardware-configuration.nix
  ]
  ++ lib.optionals useFlake [
    ../modules/syncthing.nix
    ../modules/steam.nix
  ]
  ++ lib.optionals (!useFlake) [
    ./modules/syncthing.nix
    ./modules/steam.nix
  ];

  # See for more options, they don't show up in the NixOS option search
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/config.nix
  nixpkgs.config.allowUnfreePredicate = unfreeConfig;

  nixpkgs.config = {
    firefox = {
      ffmpegSupport = true;
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
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
        locations."/".proxyPass =
          "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
      };
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thornix"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

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

  hardware.keyboard.qmk.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.desktopManager.xfce.enable = true;
  services.displayManager.defaultSession = "xfce";
  services.xserver.videoDrivers = [ "modesetting" ];

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };
  # $ pw-metadata -n settings 0 clock.force-rate 96000

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

  environment.enableAllTerminfo = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ghthor = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager"
      "docker"
      "audio"
    ];
    packages = with pkgs; [
      nitrokey-app
      ulauncher
      firefox
      chromium

      aws-sso-cli
      docker
      docker-buildx
      docker-credential-helpers
      amazon-ecr-credential-helper
      xclip
      gnumake
      # barrier # unmaintained
      obs-studio
      sshfs

      gitFull
      gh
      graphite-cli

      qmk
    ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/P1Dwjn0gppEakHqmYWD0QijlkK6JlOCp9A0tj+R8kdvGq2Ti6GyI1eRPUbrcwF41Cj2ynGQe/OgmguRxL72xIT8/ZvVtM4kqwTiMspEjMeizMNtGlGfPhmQd4CgnXyVuILrqTDNi8j8yUYEvIaBID/dt2qWd4UmgcSRZmGPmIOK7RaH9Rc69bJ9xu0KdE2u85I9nEb3t8r13kz8oggEPbqeL7RArsZLxyzVuucZr8QkpHUDjyyJWAjAg3lLX2t6RbUP8NDk+ZSKGJ6ldeVxbjupIu/o/L9XiZUqQw32Nt+WW+BGYmCI5ygvuswdkBZMACYYc96EckWzthcN4SjJP cardno:000F_D0A41346"
    ];

    shell = pkgs.bashInteractive;
  };

  # home-manager is managed standalone via `make home` / `nix run .#home`

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
    ijq
    miller # jq for csv
    tree
    wget
    ripgrep
    fd
    file

    diff-so-fancy
    gnumake
    go

    ruby
    # rubyfmt # current broken
    python3

    pass
    pwgen

    pciutils
    usbutils
    lm_sensors

    xmodmap
    xfce4-sensors-plugin
    xfce4-systemload-plugin
    xfce4-cpugraph-plugin
    xfce4-pulseaudio-plugin

    pavucontrol

    winetricks

    docker-buildx
    docker-compose
  ];

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      nerd-fonts.hack
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

  programs.mtr.enable = true;

  programs.mosh = {
    enable = true;
    openFirewall = true;
  };

  programs.firefox.enable = true;
  programs.bash = {
    completion.enable = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
  };

  # services.jellyfin = {
  #   enable = true;
  # };

  # services.transmission = {
  #   enable = true;

  #   settings = {
  #     "incomplete-dir-enabled" = false;
  #     "rpc-bind-address" = "0.0.0.0";
  #     "rpc-whitelist-enabled" = false;
  #     "rpc-host-whitelist-enabled" = false;
  #   };
  # };

  # systemd.services.transmission = {
  #   serviceConfig = {
  #     BindPaths = [
  #       "/mnt/space_round/transmission"
  #     ];
  #   };
  # };

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
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
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
