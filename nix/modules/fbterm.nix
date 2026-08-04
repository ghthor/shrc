{
  config,
  lib,
  pkgs,
  ...
}:
let
  fbtermFontNames = lib.concatStringsSep "," [
    "Hack Nerd Font Mono"
    "Hack Mono"
    "Hack"
  ];
  fbtermFontSize = 16;
  fbtermLogin = pkgs.writeShellScript "fbterm-login" ''
    export TERM=fbterm-256color
    exec ${pkgs.shadow}/bin/login "$@"
  '';
in
{
  options.programs.fbterm = {
    enable = lib.mkEnableOption "fbterm on tty2";
  };

  config = lib.mkIf config.programs.fbterm.enable {
    environment.systemPackages = [ pkgs.fbterm ];

    # Use fbterm on tty2 while retaining ordinary gettys on tty3-tty6.
    systemd.services."getty@tty2".enable = false;
    systemd.services.fbterm-tty2 = {
      description = "Framebuffer terminal on tty2";
      wantedBy = [ "getty.target" ];
      before = [ "getty.target" ];
      after = [
        "systemd-logind.service"
        "systemd-user-sessions.service"
        "getty-pre.target"
      ];
      conflicts = [ "getty@tty2.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.fbterm}/bin/fbterm --font-names='${fbtermFontNames}' --font-size=${toString fbtermFontSize} -- ${fbtermLogin}";
        Environment = "TERM=fbterm-256color";
        Restart = "always";
        RestartSec = "1s";
        TTYPath = "/dev/tty2";
        UtmpIdentifier = "tty2";
        StandardInput = "tty";
        StandardOutput = "tty";
        StandardError = "tty";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
      };
    };
  };
}
