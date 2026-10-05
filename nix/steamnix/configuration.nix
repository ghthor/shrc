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
    ];
in
{
  imports = [
    ./hardware-configuration.nix
  ]
  ++ lib.optionals (builtins.pathExists ./modules) [
    ./modules/syncthing.nix
    ./modules/steam.nix
    ./modules/fonts.nix
  ]
  ++ lib.optionals (builtins.pathExists ../modules) [
    ../modules/syncthing.nix
    ../modules/steam.nix
    ../modules/fonts.nix
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

  hardware.keyboard.qmk.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.desktopManager.xfce.enable = true;
  services.displayManager.defaultSession = "xfce";
  services.xserver.videoDrivers = [ "amdgpu" ];

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

      qmk
    ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/P1Dwjn0gppEakHqmYWD0QijlkK6JlOCp9A0tj+R8kdvGq2Ti6GyI1eRPUbrcwF41Cj2ynGQe/OgmguRxL72xIT8/ZvVtM4kqwTiMspEjMeizMNtGlGfPhmQd4CgnXyVuILrqTDNi8j8yUYEvIaBID/dt2qWd4UmgcSRZmGPmIOK7RaH9Rc69bJ9xu0KdE2u85I9nEb3t8r13kz8oggEPbqeL7RArsZLxyzVuucZr8QkpHUDjyyJWAjAg3lLX2t6RbUP8NDk+ZSKGJ6ldeVxbjupIu/o/L9XiZUqQw32Nt+WW+BGYmCI5ygvuswdkBZMACYYc96EckWzthcN4SjJP cardno:000F_D0A41346"
    ];

    shell = pkgs.bashInteractive;
  };

  # home-manager is managed standalone via `make home` / `nix run .#home`

  environment.systemPackages = with pkgs; [
    bashInteractive
    nix-bash-completions
    jq
    xfce4-sensors-plugin
    xfce4-systemload-plugin
    xfce4-cpugraph-plugin
    xfce4-pulseaudio-plugin
  ];

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
  system.stateVersion = "25.11"; # Did you read the comment?
}
