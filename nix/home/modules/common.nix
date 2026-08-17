{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  serena,
  NIX_PATH,
  ...
}:
let
  packages-base = with pkgs; [
    bashInteractive
    nix-bash-completions
    pkgs-unstable.nix-output-monitor

    htop
    btop

    screen
    expect

    tmux
    tmux-xpanes

    (pkgs.callPackage ../../packages/idr-tools.nix { })

    nodejs_22
    typescript
    typescript-language-server
    yaml-language-server
    statix # used by vim-ale

    pass
    pwgen

    ruby
    # rubyfmt # currently broken
    python3
    ruff

    marksman
    shellcheck

    vscode-json-languageserver

    fd
    ripgrep
    findutils
    eza
    tree
    bat
    stow
    viddy
    dust
    glow
    gnumake
    pkgs-unstable.gum
    bkt
    curl
    colorized-logs

    jq
    ijq

    nixfmt
    treefmt

    pkgs-unstable.aws-sso-cli

    serena.packages.${pkgs.stdenv.hostPlatform.system}.serena
  ];

  packages-base-linux = with pkgs; [
    xmodmap
  ];
in
{
  options.shrc.common.enable = lib.mkEnableOption "shrc common configuration";

  options.shrc.common.packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Additional packages to install alongside the base package set.";
  };

  config = {
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "copilot.vim"
        "graphite-cli"
        "graphite-cli-unwrapped"
        "vim-argumentative"
        "vim-addon-mw-utils"
        "vim-git"
        "claude-code"
      ];

    # https://home-manager-options.extranix.com/
    programs.home-manager.enable = true;

    news.display = "show";

    xdg.enable = true;

    programs.go = {
      enable = true;
      package = pkgs-unstable.go;
    };

    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      settings = {
        core = {
          excludesfile = "~/src/shrc/pkg/shell/.global.gitignore";
        };
      };
      includes = [ { path = "~/src/shrc/pkg/shell/.gitconfig"; } ];
    };

    programs.ssh = {
      enable = true;
      # matchBlocks = {
      #   "ghthor-devbox" = {
      #     host = "ghthor.voltus-devbox";
      #     user = "ghthor";
      #     forwardAgent = false; # handled by the gpg-agent socket forwarding
      #     extraOptions = {
      #       "RemoteForward /run/user/1000/gnupg/S.gpg-agent     /Users/willowens/.gnupg/S.gpg-agent.extra" = "";
      #       "RemoteForward /run/user/1000/gnupg/S.gpg-agent.ssh /Users/willowens/.gnupg/S.gpg-agent.ssh" = "";
      #     };
      #   };
      # };
      enableDefaultConfig = false;
      settings = {
        "*" = {
          AddKeysToAgent = false;
          Compression = false;
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = false;
          ForwardAgent = false;
          HashKnownHosts = false;
          ServerAliveCountMax = 3;
          ServerAliveInterval = 0;
          UserKnownHostsFile = "~/.ssh/known_hosts";
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          Include = "~/.orbstack/ssh/config";
        };
      };
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
      };
      gitCredentialHelper.enable = true;
    };

    programs.diff-so-fancy.enable = true;
    programs.diff-so-fancy.enableGitIntegration = true;

    programs.readline = {
      enable = true;
      extraConfig = builtins.readFile ../../../pkg/shell/.inputrc;
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
    };
    # Use direct file ref so no symlink needed and no home-manager switch required to modify the starship config
    home.sessionVariables.STARSHIP_CONFIG = lib.mkForce "${config.home.homeDirectory}/src/shrc/pkg/shell/.starship.toml";

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

    programs.kitty = {
      enable = true;
      shellIntegration.enableBashIntegration = true;
      shellIntegration.enableZshIntegration = true;
      themeFile = "Jellybeans";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      font.name = "Hack Nerd Font Mono";
    };

    programs.ghostty = {
      enable = true;
      package = lib.mkIf pkgs.stdenv.isDarwin (
        pkgs-unstable.callPackage ../../mutalisk/ghostty-bin.nix { }
      );
      enableBashIntegration = !pkgs.stdenv.isDarwin;
      enableZshIntegration = true;
      installVimSyntax = true;
      settings = {
        theme = "Jellybeans";
        font-family = "Hack Nerd Font Mono";
        fullscreen = true;
        link-url = true;
      };
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
      initExtra =
        let
          linux = ''
            eval "$(zoxide init bash)"
            eval "$(direnv hook bash)"
            eval "$(starship init bash --print-full-init)"
          '';
          darwin = ''
            eval "$(starship init bash --print-full-init)"

            if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
              builtin source "$GHOSTTY_RESOURCES_DIR/shell-integration/bash/ghostty.bash"
            fi

            eval "$(direnv hook bash)"
            eval "$(zoxide init bash)"
          '';
          termNotDumb = if pkgs.stdenv.isDarwin then darwin else linux;
        in
        ''
          source $HOME/src/shrc/pkg/shell/.bash_interactive
          if [[ $TERM != "dumb" ]]; then
            ${termNotDumb}
          fi
        '';
    };

    home.packages =
      packages-base
      ++ lib.optionals pkgs.stdenv.isLinux packages-base-linux
      ++ config.shrc.common.packages;

  };
}
