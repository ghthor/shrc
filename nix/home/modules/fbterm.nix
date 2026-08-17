{
  config,
  lib,
  ...
}:
let
  fbtermFonts = [
    "Hack Nerd Font Mono"
    "Hack Mono"
    "Hack"
  ];
in
{
  options.shrc.fbterm.enable = lib.mkEnableOption "FbTerm configuration";

  config = lib.mkIf config.shrc.fbterm.enable {
    home.file.".fbtermrc".text = ''
      # FbTerm configuration used by the fbterm-tty2 service and normal sessions.
      font-names=${lib.concatStringsSep "," fbtermFonts}
      font-size=16

      ## do not turn on this when using tmux, tmux will have display problems
      ## treat ambiguous width characters as wide
      ambiguous-wide=no

      # cursor shape: 0 = underline, 1 = block
      # cursor flash interval in milliseconds, 0 means disable flashing
      cursor-shape=1
      cursor-interval=0
    '';
  };
}
