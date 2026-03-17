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
in
{
  imports = [
    ./hardware-configuration.nix
  ]
  ++ lib.optionals useFlake [
    ../modules/syncthing.nix
    ../modules/steam.nix
    attrs.home-manager.nixosModules.default

  ]
  ++ lib.optionals (!useFlake) [
    ./modules/syncthing.nix
    ./modules/steam.nix
    <home-manager/nixos>
  ];

  # See for more options, they don't show up in the NixOS option search
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/config.nix
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      # Add additional package names here
      "nomad"

      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"

      "graphite-cli"

      "keymapp"
    ];

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
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "steamnix"; # Define your hostname.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.desktopManager.xfce.enable = true;
  services.displayManager.defaultSession = "xfce";
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  services.udev.packages = [
    pkgs.qmk-udev-rules
  ];

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

  environment.enableAllTerminfo = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ghthor = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager"
      "audio"
    ];
    packages = with pkgs; [
      ulauncher
      xclip
      gnumake
      gitFull
      keymapp # moonlander configurator
    ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/P1Dwjn0gppEakHqmYWD0QijlkK6JlOCp9A0tj+R8kdvGq2Ti6GyI1eRPUbrcwF41Cj2ynGQe/OgmguRxL72xIT8/ZvVtM4kqwTiMspEjMeizMNtGlGfPhmQd4CgnXyVuILrqTDNi8j8yUYEvIaBID/dt2qWd4UmgcSRZmGPmIOK7RaH9Rc69bJ9xu0KdE2u85I9nEb3t8r13kz8oggEPbqeL7RArsZLxyzVuucZr8QkpHUDjyyJWAjAg3lLX2t6RbUP8NDk+ZSKGJ6ldeVxbjupIu/o/L9XiZUqQw32Nt+WW+BGYmCI5ygvuswdkBZMACYYc96EckWzthcN4SjJP cardno:000F_D0A41346"
    ];

    shell = pkgs.bashInteractive;
  };

  home-manager.users.ghthor =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      xdg.enable = true;

      home.packages = with pkgs; [
        bashInteractive
        vlc

        nixfmt-tree
      ];

      services.pasystray.enable = true;

      programs.go.enable = true;

      programs.ghostty = {
        enable = true;
        enableBashIntegration = false; # breaks starship
        # settings = {
        #   initial-command = "${pkgs.bashInteractive}/bin/bash -l -i";
        # };
      };

      programs.git = {
        enable = true;
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
        pinentryPackage = pkgs.pinentry-gtk2;
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
        extraConfig = builtins.head (
          lib.optional useFlake (builtins.readFile ../../pkg/shell/.inputrc)
          ++ lib.optional (!useFlake) (builtins.readFile /home/ghthor/src/shrc/pkg/shell/.inputrc)
        );
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
        settings = builtins.head (
          lib.optional useFlake (builtins.fromTOML (builtins.readFile ../../pkg/shell/.starship.toml))
          ++ lib.optional (!useFlake) (
            builtins.fromTOML (builtins.readFile /home/ghthor/src/shrc/pkg/shell/.starship.toml)
          )
        );
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

      programs.lutris = {
        enable = true;
        steamPackage = osConfig.programs.steam.package;
        defaultWinePackage = pkgs.proton-ge-bin;
        protonPackages = [
          pkgs.proton-ge-bin
        ];
        winePackages = [
          pkgs.wineWow64Packages.full
        ];
        extraPackages = with pkgs; [
          mangohud
          winetricks
          gamescope
          gamemode
          umu-launcher
        ];
      };

      # The state version is required and should stay at the version you
      # originally installed.
      home.stateVersion = "25.11";
    };

  environment.systemPackages = with pkgs; [
    bashInteractive
    nix-bash-completions
    jq

    xfce.xfce4-cpugraph-plugin
    xfce.xfce4-systemload-plugin
    xfce.xfce4-sensors-plugin
  ];

  programs.firefox.enable = true;
  programs.bash = {
    completion.enable = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
  };

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
  # networking.firewall.enable = false;

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
  system.stateVersion = "25.11"; # Did you read the comment?
}
