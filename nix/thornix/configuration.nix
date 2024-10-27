# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }@attrs:
let
  useFlake = if (builtins.hasAttr "useFlake" attrs) then attrs.useFlake else false;
in
{
  imports =
    [
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

  # See for more options, they don't show up in the NixOS option search
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/config.nix
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # Add additional package names here
    "nomad"

    "steam"
    "steam-original"
    "steam-run"

    "graphite-cli"
  ];

  nixpkgs.config = {
    firefox = {
      ffmpegSupport = true;
    };
  };

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
  services.displayManager.defaultSession = "xfce";
  services.xserver.videoDrivers = [ "modesetting" ];

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

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
      barrier
      obs-studio
      sshfs
      gitFull
      gh
      graphite-cli
    ];
    openssh.authorizedKeys.keys = [ ];

    shell = pkgs.bashInteractive;
  };

  home-manager.users.ghthor = { pkgs, ... }: {
    xdg.enable = true;

    home.packages = with pkgs; [
      bashInteractive
      comma
      docker

      nodejs_22
      typescript

      statix

      ruby
      # rubyfmt # current broken

      vlc
      peek
    ];

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

    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        vim-pathogen
        vim-addon-mw-utils
        tlib_vim

        jellybeans-vim
        ctrlp-vim
        zoxide-vim
        vim-tabby
        nerdtree
        lightline-vim
        vim-commentary
        vim-repeat
        vim-surround
        vim-vinegar
        indentLine

        vim-nix

        vim-terraform

        # https://dev.to/braybaut/integrate-terraform-language-server-protocol-with-vim-38g
        coc-nvim
        ale

        vim-gitgutter
        vim-git
        vim-fugitive
        vim-rhubarb
        vim-argumentative
      ];
      settings = { ignorecase = true; };
      extraConfig = ''
        source $HOME/src/shrc/pkg/vim/.vimrc
      '';
    };

    programs.ssh = {
      enable = true;
      matchBlocks = {
        "ghthor-devbox" = {
          host = "ghthor.voltus-devbox";
          forwardAgent = false; # handled by the gpg-agent socket forwarding
          extraOptions = {
            "RemoteForward /run/user/1000/gnupg/S.gpg-agent     /run/user/1000/gnupg/S.gpg-agent.extra" = "";
            "RemoteForward /run/user/1000/gnupg/S.gpg-agent.ssh /run/user/1000/gnupg/S.gpg-agent.ssh" = "";
          };
        };
        "ssm" = {
          host = "i-* mi-*";
          extraOptions = {
            ProxyCommand  = ''sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"'';
          };
        };
      };
      extraConfig = ''
      '';
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
        ++ lib.optional (!useFlake) (builtins.fromTOML (builtins.readFile /home/ghthor/src/shrc/pkg/shell/.starship.toml))
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

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "23.11";
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  programs.bash = {
    completion.enable = true;
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
    # rubyfmt # current broken
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
    xfce.xfce4-pulseaudio-plugin
    pavucontrol

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

  programs.mtr.enable = true;

  programs.mosh = {
    enable = true;
    openFirewall = true;
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
