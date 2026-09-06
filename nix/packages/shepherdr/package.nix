{
  buildGo127Module,
  fetchFromGitHub,
  lib,
}:

buildGo127Module rec {
  pname = "shepherdr";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "luiscleto";
    repo = "shepherdr";
    tag = "v${version}";
    hash = "sha256-/pizgWb/5as8OwOtEN1wt9+24ewW62qDH+Oas1HIPUg=";
  };

  vendorHash = "sha256-MESwquBSXN8H/g+4rmYqjILm4zNLE1IzyhARl4J8z1U=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.releaseVersion=v${version}"
  ];

  meta = {
    description = "Web interface for managing local Herdr terminals and workspaces";
    homepage = "https://github.com/luiscleto/shepherdr";
    license = lib.licenses.mit;
    mainProgram = "shepherdr";
  };
}
