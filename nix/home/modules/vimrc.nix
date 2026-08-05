{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  vimrcFile = pkgs.vimUtils.vimrcFile {
    customRC = "";
    packages.myPlugins = {
      start = with pkgs.vimPlugins; [
        vim-pathogen
        vim-addon-mw-utils
        tlib_vim

        jellybeans-vim
        ctrlp-vim
        zoxide-vim

        nerdtree
        lightline-vim
        vim-commentary
        vim-repeat
        vim-surround
        vim-vinegar
        indentLine

        vim-nix
        vim-cue

        vim-terraform

        # https://dev.to/braybaut/integrate-terraform-language-server-protocol-with-vim-38g
        coc-nvim
        ale

        vim-gitgutter
        vim-git
        pkgs-unstable.vimPlugins.vim-fugitive
        pkgs-unstable.vimPlugins.vim-rhubarb
        vim-argumentative

        zeavim-vim

        fzf-vim
      ];
    };
  };
in
{
  home.activation.linkDotVim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    source ${./link_path.sh}

    shrc_link_path \
      "$HOME/src/shrc/pkg/vim/.vim" \
      "$HOME/.vim"
  '';

  home.file.".vimrc" = {
    text = ''
      source ${vimrcFile.outPath}
      source $HOME/src/shrc/pkg/vim/.vimrc
    '';
    target = ".vimrc";
  };
}
