{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  hermes-agent,
  ...
}:

let
  cfg = config.shrc.hermes;

  hostSystem = pkgs.stdenv.hostPlatform.system;

  # Container images are Linux images; on Darwin they are built on the Orb VM
  # for the matching Linux architecture.
  containerSystem = lib.replaceStrings [ "darwin" ] [ "linux" ] hostSystem;

  signalCliImageName = "ghthor/signal-cli";
  signalCliImage = "${signalCliImageName}:${pkgs-unstable.signal-cli.version}";

  # Evaluated at runtime by hermes-build-signal-cli so the image derivation is
  # instantiated for the container system rather than the host system.
  signalCliImageNix = pkgs.writeText "hermes-signal-cli-image.nix" ''
    import ${./hermes/signal-cli}/container.nix {
      name = "${signalCliImageName}";
      pkgs = import ${pkgs-unstable.path} { system = "${containerSystem}"; };
    }
  '';

  hermes-build-image = pkgs.writeShellApplication {
    name = "hermes-build-image";
    runtimeInputs = with pkgs; [ coreutils ];
    text = builtins.readFile ./hermes/hermes-build-image.sh;
  };

  hermes-build-minimal = pkgs.writeShellApplication {
    name = "hermes-build-minimal";
    runtimeInputs = [ hermes-build-image ];
    text = ''
      export HERMES_CONTAINER_COMMIT=${lib.escapeShellArg cfg.container.commit}
    ''
    + builtins.readFile ./hermes/hermes-build-minimal.sh;
  };

  hermes-build-signal-cli = pkgs.writeShellApplication {
    name = "hermes-build-signal-cli";
    runtimeInputs = [ hermes-build-image ];
    text = ''
      export HERMES_SIGNAL_CLI_IMAGE=${lib.escapeShellArg signalCliImage}
      export HERMES_SIGNAL_CLI_IMAGE_NIX=${signalCliImageNix}
    ''
    + builtins.readFile ./hermes/hermes-build-signal-cli.sh;
  };

  hermes = pkgs.writeShellApplication {
    name = "hermes";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      socat
    ];
    text = ''
      export HERMES_IMAGE=${lib.escapeShellArg cfg.image}
      export HERMES_NATIVE=${lib.getExe cfg.package}
    ''
    + builtins.readFile ./hermes/hermes.sh;
  };

  hermesd = pkgs.writeShellApplication {
    name = "hermesd";
    runtimeInputs = [ hermes-build-signal-cli ];
    text = ''
      export HERMES_IMAGE=${lib.escapeShellArg cfg.image}
      export HERMES_SIGNAL_CLI_IMAGE=${lib.escapeShellArg signalCliImage}
      export HERMESD_COMPOSE_FILE=${./hermes/hermesd-compose.yaml}
      export HERMESD_CONTAINER_NAME=${lib.escapeShellArg cfg.gateway.containerName}
    ''
    + builtins.readFile ./hermes/hermesd.sh;
  };

  signal-cli = pkgs.writeShellApplication {
    name = "signal-cli";
    runtimeInputs = [ hermesd ];
    text = builtins.readFile ./hermes/hermes-signal-cli.sh;
  };
in
{
  options.shrc.hermes = {
    enable = lib.mkEnableOption "Hermes agent Docker wrapper and container build helper";

    image = lib.mkOption {
      type = lib.types.str;
      default = "nousresearch/hermes-agent:0.21.3-minimal";
      description = "Docker image run by the `hermes` command.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = hermes-agent.packages.${hostSystem}.minimal;
      defaultText = lib.literalExpression "hermes-agent.packages.\${system}.minimal";
      description = ''
        Native hermes-agent package. The `hermes` wrapper routes subcommands
        that must run on the host (e.g. `hermes mcp`) to this binary instead
        of the Docker container.
      '';
    };

    container.commit = lib.mkOption {
      type = lib.types.str;
      default = hermes-agent.rev;
      defaultText = lib.literalExpression "hermes-agent.rev";
      description = "Default ghthor/hermes-agent commit built by `hermes-build-minimal`.";
    };

    gateway.containerName = lib.mkOption {
      type = lib.types.str;
      default = "hermes-gateway";
      description = "Docker container name of the gateway service run by `hermesd`.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      hermes
      hermesd
      signal-cli
      hermes-build-image
      hermes-build-minimal
      hermes-build-signal-cli
    ];
  };
}
