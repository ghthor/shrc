{
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
{
  programs.lutris = {
    enable = true;
    steamPackage = lib.mkIf (lib.hasAttrByPath [ "programs" "steam" "package" ] osConfig) (
      lib.getAttrFromPath [ "programs" "steam" "package" ] osConfig
    );
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
}
