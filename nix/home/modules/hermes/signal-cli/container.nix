# Container image for the signal-cli daemon used as a Hermes gateway sidecar.
#
# Evaluated for a Linux system; see hermes.nix for how it is built and loaded
# into Docker. `pkgs` must be a nixpkgs instantiated for the target system.
{
  pkgs,
  name ? "ghthor/signal-cli",
}:

let
  inherit (pkgs) lib libmatthew_java dbus_java;

  # nixpkgs' signal-cli still puts libmatthew-java and dbus-java 2.x on the
  # classpath / java.library.path, a leftover from the dbus-java 2.x era.
  # Modern signal-cli bundles dbus-java 5 (pure Java, jnr-unixsocket
  # transport) in its own lib/, so those references are unused, yet dbus-java
  # 2.x pulls a full OpenJDK 8 into the runtime closure (~370 MiB). Dropping
  # them shrinks the image without changing behaviour.
  signal-cli = pkgs.signal-cli.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      substituteInPlace $out/bin/signal-cli \
        --replace-fail ":${libmatthew_java}/lib/jni" "" \
        --replace-fail ":${dbus_java}/share/java/dbus" ""
    '';

    # Ensure the legacy references really are gone from the runtime closure.
    disallowedReferences = [
      libmatthew_java
      dbus_java
    ];
  });

  dataDir = "/var/lib/signal-cli";
in
pkgs.dockerTools.streamLayeredImage {
  inherit name;
  tag = signal-cli.version;

  contents = [
    signal-cli
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.fakeNss
  ];

  extraCommands = ''
    mkdir -p -m 1777 tmp
    mkdir -p ${lib.removePrefix "/" dataDir}
  '';

  config = {
    Entrypoint = [
      (lib.getExe signal-cli)
      "--config"
      dataDir
    ];
    Cmd = [
      "daemon"
      "--http"
      "0.0.0.0:8080"
    ];
    WorkingDir = dataDir;
    # Without a UTF-8 locale the JVM's stdout.encoding falls back to ASCII and
    # the QR code printed by `signal-cli link` renders as '?' characters.
    Env = [ "LANG=C.UTF-8" ];
    Volumes."${dataDir}" = { };
    ExposedPorts."8080/tcp" = { };
  };
}
