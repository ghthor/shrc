{
  config,
  lib,
  pkgs-unstable,
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
          src = pkgs-unstable.zsh-completion-sync;
        }
      ];
      initContent = ''
        zstyle ':completion-sync:compinit:custom' enabled true
        zstyle ':completion-sync:compinit:custom' command 'source ${pkgs-unstable.zsh-autocomplete}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh'
      '';
    };
  };
}
