with import <nixpkgs> { };

vim_configurable.customize {
  name = "vim";
  vimrcConfig.customRC = ''
    ;
  '';
  # Use the default plugin list shipped with nixpkgs
  vimrcConfig.packages.myVimPackage = with pkgs.vimPlugins; {
    # loaded on launch
    start = [
      ale
      vim-nix
    ];
    # manually loadable by calling `:packadd $plugin-name`
    opt = [ ];
    # To automatically load a plugin when opening a filetype, add vimrc lines like:
    # autocmd FileType php :packadd phpCompletion
  };
}
