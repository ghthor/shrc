{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  unzip,
}:

let
  sources = {
    x86_64-linux = {
      url = "https://files.pythonhosted.org/packages/f5/1d/d6d7466aaf4c4e31aa359447120a977984c01aca978818f8f32dcb669e83/idr_tools-0.2.1-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-KsxzXq2QHbWxAZxR/fPQycy343Gmvg2n5GjaiJO08oQ=";
    };
    aarch64-darwin = {
      url = "https://files.pythonhosted.org/packages/8d/6b/5a940a46fba19046afd232ba8a18abd70e416aef9e90a198cf2796e17c06/idr_tools-0.2.1-py3-none-macosx_11_0_arm64.whl";
      hash = "sha256-1vOMEx6THICefo3aFKXPeyGOpMby7ixRvDlr4wMqHOk=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "idr-tools";
  version = "0.2.1";

  src = fetchurl source;

  nativeBuildInputs = [ unzip ] ++ lib.optional stdenv.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenv.isLinux stdenv.cc.cc.lib;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    unzip -q $src -d unpacked
    install -Dm755 unpacked/idr_tools-0.2.1.data/scripts/idr $out/bin/idr
  '';

  meta = {
    description = "Tooling to support Implementation Decision Records";
    homepage = "https://github.com/wlach/idr-tools";
    license = lib.licenses.mit;
    mainProgram = "idr";
    platforms = builtins.attrNames sources;
  };
}
