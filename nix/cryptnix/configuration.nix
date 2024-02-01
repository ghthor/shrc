# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./syncthing.nix
      ./steam.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cryptnix"; # Define your hostname.
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
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ghthor = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      albert
      firefox
      aws-sso-cli
      git-extras
      gh
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5sUE5ZiFc4Rta/4s5cDib0RTA0roZmlC6R7xfUvr8oymXbvoj6Pv1dE5iuETWtXsxN5Cp9tbcfuxI56f3aZQRdUbzqs4WcXVr/cuIBIBSKR7o5Q1Y2/e3S0qR7AODeGJvT1L9sSPnufldC0Xls3TCuCgQlYydWFJN/CT2fq080nd0zSG1af71tPenHfER12BmYQMjyOg/pobpm1oRaSzX6Mr/p1LF4EhagAUOQqZolE6RQdoKefKEVGk1FSHUsLtaIp+1niFFrVmEZQ/7Ti1PE8dW8NszLJHJwV84VKrW3oM8s8l/6CnpfQUsv6XleQUfzBz1sI/F3qQKqUV3GXHkAoXOOK0HxrphXJxKBDwQzK9eOCda/8U0vQKM4F7dw3V3XQUEC0yRunyUZhxg/DYGWbguRDQOMmaX5pbAjfmpw/4zImjfQ2qur54EEKjU1xjFBsEeSdbm6c1QWeB2yogziXqo9rJFJrTqJJcOjyffYSvCn+dQ0aeC8ORwEmZ0ZoltQgfQoOUgeHKuJbVVU+0v8FIN2uzz3wYageDVdJVm5ePM99TdHGeLE2nF6KHmigqcCPxknL9XYcIioiqHzQeF6sc/QvC+ojxAje6Fx/u2DBkGqvcRShLFYqCErzYguubCp+ejWsazPURVXXCUuid23tseaLj/tgtr4AdGo9rBYQ== ghthor@gmail.com"
    ];
  };

  programs.vim.defaultEditor = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    starship
    fzf
    stow
    zoxide

    (import ./vim.nix)
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

    git
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
  system.copySystemConfiguration = true;

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

