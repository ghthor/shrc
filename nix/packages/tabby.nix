{
  fetchurl,
  stdenv,
  lib,
}:

let
  targetOs = if stdenv.isDarwin then "apple-darwin" else "linux";
  targetArch = if stdenv.isAarch64 then "aarch64" else "x86_64";

  hashes = {
    aarch64-apple-darwin = "sha256-SfFoG0EVSbkujj839pdiML/U+KRLqFo4XKISzDm0Rjs=";
    x86_64-linux = ""; # TODO
  };
in
stdenv.mkDerivation rec {
  name = "tabby-${version}";

  version = "0.28.0";

  # https://nixos.wiki/wiki/Packaging/Binaries
  src = fetchurl {
    # url = "https://github.com/TabbyML/tabby/releases/download/v0.28.0/tabby_aarch64-apple-darwin.tar.gz"
    url = "https://github.com/TabbyML/tabby/releases/download/v${version}/tabby_${targetArch}-${targetOs}.tar.gz";
    sha256 = hashes."${targetArch}-${targetOs}";
  };

  nativeBuildInputs = [ ];

  sourceRoot = ".";

  # TODO: use llama-server from nixpkgs
  installPhase = ''
    install -m755 -D tabby_${targetArch}-${targetOs}/tabby        $out/bin/tabby
    install -m755 -D tabby_${targetArch}-${targetOs}/llama-server $out/bin/llama-server
  '';

  meta = with lib; {
    homepage = "";
    description = "";
    platforms = platforms.darwin;
  };
}
