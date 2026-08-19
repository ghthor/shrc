{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.shrc.zsh.enable = lib.mkEnableOption "Zsh configuration";

  config = lib.mkIf config.shrc.zsh.enable {
    programs.zsh = {
      enable = true;
      plugins = [
        {
          name = "zsh-completion-sync";
          src = pkgs.zsh-completion-sync;
        }
      ];
    };
  };
}
