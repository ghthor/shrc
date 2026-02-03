{
  lib,
  hmlib,
  pkgs,
  pkgs-unstable,
  NIX_PATH,
  ...
}:
let
  homeDirectory = "/Users/willowens";
in
{
  news.display = "show";

  # This is required information for home-manager to do its job
  home = {
    stateVersion = "23.11";
    username = "willowens";
    inherit homeDirectory;
    packages = with pkgs; [
      bashInteractive
      nix-bash-completions
      pkgs-unstable.nix-output-monitor

      pkgs-unstable.aws-sso-cli

      (pkgs.callPackage ../packages/tabby.nix { })

      pass
      pwgen

      ruby
      # rubyfmt # broken in nixos-unstable
      python3
      ruff

      fd
      ripgrep
      eza
      tree
      bat
      stow
      viddy
      dust

      gitFull
      pkgs-unstable.graphite-cli

      typescript

      htop
      screen
      tmux
      tmux-xpanes
      mosh

      jq
      ijq
      gnumake
      findutils

      expect

      vimPlugins.coc-nvim
      nodejs_22
      statix # used by vim-ale

      pkgs-unstable.gum

      pkgs-unstable.amazon-ecr-credential-helper
    ];
  };

  # https://mipmip.github.io/home-manager-option-search/?query=
  programs.home-manager.enable = true;
  home.sessionVariables = {
    EDITOR = "vim";
    inherit NIX_PATH;
  };
  xdg.enable = true;

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "ghthor-devbox" = {
        host = "ghthor.voltus-devbox";
        user = "ghthor";
        forwardAgent = false; # handled by the gpg-agent socket forwarding
        extraOptions = {
          "RemoteForward /run/user/1000/gnupg/S.gpg-agent     /Users/willowens/.gnupg/S.gpg-agent.extra" = "";
          "RemoteForward /run/user/1000/gnupg/S.gpg-agent.ssh /Users/willowens/.gnupg/S.gpg-agent.ssh" = "";
        };
      };
      "ssm" = {
        host = "i-* mi-*";
        extraOptions = {
          ProxyCommand = ''sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"'';
        };
      };
    };
    extraConfig = ''
      Include ~/.orbstack/ssh/config
    '';
  };

  programs.go.enable = true;
  programs.git = {
    enable = true;
    diff-so-fancy.enable = true;
    package = pkgs.gitFull;
    extraConfig = {
      core = {
        excludesfile = "~/src/shrc/pkg/shell/.global.gitignore";
      };
    };
    includes = [ { path = "~/src/shrc/pkg/shell/.gitconfig"; } ];
  };

  programs.gh = {
    enable = true;
    package = pkgs-unstable.gh;
    settings = {
      git_protocol = "ssh";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
        pvw = "pr view --web";
      };
      prompt = "enabled";
    };
  };

  home.file."gpg-agent.conf" = {
    text = ''
      pinentry-program /opt/homebrew/bin/pinentry-mac
      enable-ssh-support
      extra-socket $HOME/.gnupg/S.gpg-agent.extra
      default-cache-ttl 600
      max-cache-ttl 7200
      debug-level none
      # debug-pinentry
      log-file $HOME/.gnupg/gpg-agent.log
    '';
    target = ".gnupg/gpg-agent.conf";
  };

  # TODO: generate this shell script from nix instead of
  #       it being outside of nix
  home.file."brew_install_stdenv" = {
    source = ./brew_install_stdenv;
    target = "bin/brew_install_stdenv";
  };

  home.activation.linkTabbyPlist = hmlib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ln -sf $VERBOSE_ARG \
      ${homeDirectory}/src/shrc/nix/mutalisk/tabby.plist \
      ${homeDirectory}/Library/LaunchAgents/com.ghthor.tabby.plist
  '';
  home.activation.linkDotVim = hmlib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run [ -L "${homeDirectory}/.vim" ] || \
      run ln -sf $VERBOSE_ARG \
        ${homeDirectory}/src/shrc/pkg/vim/.vim/ \
        ${homeDirectory}/.vim
  '';
  home.file = {
    ".vimrc" =
      let
        vimrcFile = pkgs.vimUtils.vimrcFile {
          customRC = "";
          packages.myPlugins = {
            start = with pkgs.vimPlugins; [
              vim-pathogen
              vim-addon-mw-utils
              tlib_vim

              jellybeans-vim
              ctrlp-vim
              zoxide-vim

              (pkgs.callPackage ../packages/vim-tabby.nix { })

              nerdtree
              lightline-vim
              vim-commentary
              vim-repeat
              vim-surround
              vim-vinegar
              indentLine

              vim-nix

              vim-terraform

              # https://dev.to/braybaut/integrate-terraform-language-server-protocol-with-vim-38g
              coc-nvim
              ale

              vim-gitgutter
              vim-git
              pkgs-unstable.vimPlugins.vim-fugitive
              pkgs-unstable.vimPlugins.vim-rhubarb

              fzf-vim
            ];
          };
        };
      in
      {
        text = ''
          source ${vimrcFile.outPath}
          source $HOME/src/shrc/pkg/vim/.vimrc
        '';
        target = ".vimrc";
      };
  };

  # Still needs to be brew installed for Kitty.app
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    themeFile = "Jellybeans";
    font.name = "Hack Nerd Font Mono";
  };

  # Still installed with brew for Ghostty.app
  programs.ghostty = {
    enable = true;
    package = (pkgs-unstable.callPackage ./ghostty-bin.nix { });
    # manually enabled via initExtra cause HomeManager ordering is wrong
    enableBashIntegration = false;
    enableZshIntegration = true;
    installVimSyntax = true;
    settings = {
      theme = "Jellybeans";
      font-family = "Hack Nerd Font Mono";
    };
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "xterm-kitty";
    shell = "${pkgs.bash}/bin/bash";
    plugins = [ pkgs.tmuxPlugins.cpu ];
  };
  home.sessionVariables.TMUX_XPANES_EXEC = "tmux -2"; # force tmux from xpanes to be 256color

  programs.readline = {
    enable = true;
    extraConfig = builtins.readFile ../../pkg/shell/.inputrc;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # bash eval ordering matters so managing it manually
  programs.starship = {
    enable = true;
    enableZshIntegration = false; # Manually enabled via initExtra
    enableBashIntegration = false;
    settings = builtins.fromTOML (builtins.readFile ../../pkg/shell/.starship.toml);
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;
    nix-direnv.enable = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    initContent =
      let
        initExtra = lib.mkOrder 1000 (builtins.readFile ./zshrc);
      in
      lib.mkMerge [
        initExtra
      ];
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export BASHRC_HOME_MANAGER=1
      export NIX_PATH="${NIX_PATH}"
      source $HOME/src/shrc/pkg/shell/.bash_noninteractive

      # Avoid running any of the starship/zoxide/direnv sourcing again
      if [ ! -z "$DIRENV_IN_ENVRC" ]; then
        return
      fi
    '';
    initExtra = ''
      source $HOME/src/shrc/pkg/shell/.bash_interactive

      if [[ $TERM != "dumb" ]]; then
        eval "$(starship init bash --print-full-init)"

        if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
          builtin source "$GHOSTTY_RESOURCES_DIR/shell-integration/bash/ghostty.bash"
        fi

        eval "$(direnv hook bash)"
        eval "$(zoxide init bash)"
      fi
    '';
  };
}
