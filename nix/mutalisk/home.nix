{ pkgs, ... }: {
  # This is required information for home-manager to do its job
  home = {
    stateVersion = "23.11";
    username = "willowens";
    homeDirectory = "/Users/willowens";
    packages = with pkgs; [
      ruby
      rubyfmt
      bashInteractive
      pass
      fd
      eza
      tree
      bat
      stow
    ];
  };

  # https://mipmip.github.io/home-manager-option-search/?query=
  programs.home-manager.enable = true;

  programs.go.enable = true;
  programs.git = {
    enable = true;
    diff-so-fancy.enable = true;
    package = pkgs.gitFull;
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      aliases = {
        co = "pr checkout";
      };
      prompt = "enabled";
    };
  };

  home.file."gpg-agent.conf" = {
    text = ''
      pinentry-program /opt/homebrew/bin/pinentry-mac
      enable-ssh-support
      default-cache-ttl 600
      max-cache-ttl 7200
      debug-level none
      log-file $HOME/.gnupg/gpg-agent.log
    '';
    target = ".gnupg/gpg-agent.conf";
  };

  home.file."brew_install_stdenv" = {
    source = ./brew_install_stdenv;
    target = "bin/brew_install_stdenv";
  };

  # Still needs to be brew installed for Kitty.app
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    theme = "Jellybeans";
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = false; # Manually enabled via initExtra
    settings = (builtins.fromTOML (builtins.readFile ../../pkg/shell/.starship.toml));
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
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
    enableAutosuggestions = true;
    initExtraFirst = ''
    '';
    initExtra = builtins.readFile ./zshrc;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export BASHRC_HOME_MANAGER=1
    '';
    initExtra = builtins.readFile ../../pkg/shell/.bashrc;
  };
}
