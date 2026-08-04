{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.programs.fonts.enable = lib.mkEnableOption "the system font configuration";

  config = lib.mkIf config.programs.fonts.enable {
    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        nerd-fonts.hack
      ];
      fontconfig = {
        defaultFonts.monospace = [ "Hack Nerd Font Mono" ];
        useEmbeddedBitmaps = true;
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <match target="font">
              <edit mode="assign" name="antialias">
                <bool>true</bool>
              </edit>
              <edit mode="assign" name="embeddedbitmap">
                <bool>false</bool>
              </edit>
              <edit mode="assign" name="hinting">
                <bool>true</bool>
              </edit>
              <edit mode="assign" name="hintstyle">
                <const>hintslight</const>
              </edit>
              <edit mode="assign" name="lcdfilter">
                <const>lcddefault</const>
              </edit>
              <edit mode="assign" name="rgba">
                <const>rgb</const>
              </edit>
            </match>
          </fontconfig>
        '';
      };
    };
  };
}
