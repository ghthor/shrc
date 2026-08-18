{
  config,
  lib,
  pkgs-unstable,
  ...
}:
let
  aws-sso-cli = pkgs-unstable.writeShellScriptBin "aws-sso" ''
    exec ${pkgs-unstable.aws-sso-cli}/bin/aws-sso "$@"
  '';
in
{
  options.shrc.aws-sso-cli.enable = lib.mkEnableOption "AWS SSO CLI configuration";

  config = lib.mkIf config.shrc.aws-sso-cli.enable {
    home.packages = [ aws-sso-cli ];
  };
}
