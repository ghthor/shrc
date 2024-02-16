{ pkgs, ... }: {
  # This is required information for home-manager to do its job
  home = {
    stateVersion = "23.11";
    username = "willowens";
    homeDirectory = "/Users/willowens";
    packages = with pkgs; [
      ruby
      rubyfmt
    ];
  };

  programs.home-manager.enable = true;
  # I use fish, but bash and zsh work just as well here. This will setup
  # the shell to use home-manager properly on startup, neat!

  programs.starship = {
    enable = true;
    enableZshIntegration = false; # Manually enabled via initExtra
    settings = (builtins.fromTOML (builtins.readFile ../../pkg/shell/.starship.toml));
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtraFirst = ''
    '';
    initExtra = builtins.readFile ./zshrc;
  };
}
