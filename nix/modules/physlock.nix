{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.physlock-nitrokey;
  nitrokeyDetached = pkgs.writeShellScript "nitrokey-detached" ''
    printf 'Nitrokey detached at: %s\n' $(${pkgs.coreutils}/bin/date --iso-8601=seconds)
    ${pkgs.systemd}/bin/systemctl start physlock.service
  '';
in
{
  options.services.physlock-nitrokey.enable = lib.mkEnableOption "physlock locking when the Nitrokey is detached";

  config = lib.mkIf cfg.enable {
    services.physlock.enable = true;

    systemd.services.nitrokey-detached = {
      description = "Record Nitrokey detachment";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = nitrokeyDetached;
      };
    };

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{PRODUCT}=="20a0/42b2/*", RUN+="${pkgs.systemd}/bin/systemctl stop physlock.service"
      ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{PRODUCT}=="20a0/42b2/*", RUN+="${pkgs.systemd}/bin/systemctl --no-block start nitrokey-detached.service"
    '';
  };
}
