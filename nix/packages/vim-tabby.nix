{
  lib,
  vimUtils,
  fetchFromGitHub,
}:

vimUtils.buildVimPlugin {
  pname = "vim-tabby";
  version = "2021-11-20";
  src = fetchFromGitHub {
    owner = "TabbyML";
    repo = "vim-tabby";
    # https://github.com/TabbyML/vim-tabby/commit/ba271385aaf97e6f30ebddbb6f00085db13727b8
    rev = "ba271385aaf97e6f30ebddbb6f00085db13727b8";
    sha256 = "sha256-Q1TBOfeA3GPArellp4FvZVf2a8NXB6DOJAQtKA80JAo=";
  };
  meta.homepage = "https://github.com/TabbyML/vim-tabby/";
  meta.hydraPlatforms = [ ];
}
