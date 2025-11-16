{
  config,
  lib,
  pkgs,
  ...
}:

{
  services = {
    syncthing = {
      enable = true;
      user = "ghthor";
      dataDir = "/home/ghthor/Sync"; # Default folder for new synced folders
      configDir = "/home/ghthor/.config/syncthing"; # Folder for Syncthing's settings and keys
    };
  };
}
