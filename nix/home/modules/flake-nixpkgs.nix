{
  config,
  lib,
  pkgs,
  ...
}:
let
  flake-lock = builtins.fromJSON (builtins.readFile ../../flake.lock);
  nixpkgs-input-names = lib.filter (lib.hasPrefix "nixpkgs") (
    builtins.attrNames flake-lock.nodes.root.inputs
  );
  nixpkgs-registry-pins = map (
    name:
    let
      locked = flake-lock.nodes.${name}.locked;
      url = "${locked.type}:${locked.owner}/${locked.repo}/${locked.rev}";
    in
    "${pkgs.nix}/bin/nix registry pin ${lib.escapeShellArg name} ${lib.escapeShellArg url}"
  ) nixpkgs-input-names;
  nixpkgs-registry-info = pkgs.writeShellApplication {
    name = "nixpkgs-registry-info";
    runtimeInputs = [ pkgs.nix ];
    text = ''
      ${lib.concatMapStringsSep "\n" (name: ''
        printf '\n=== ${name} ===\n'
        nix flake metadata ${lib.escapeShellArg name}
      '') nixpkgs-input-names}
    '';
  };
in
{
  config = {
    home.activation.nixpkgsRegistry = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.concatStringsSep "\n" nixpkgs-registry-pins}
    '';

    home.packages = [ nixpkgs-registry-info ];
  };
}
