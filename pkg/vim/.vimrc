set nocompatible
set noedcompatible

set hidden

set clipboard^=unnamed

set autowrite

" Setup OCaml Plugin
let g:opamshare = substitute(system('opam config var share'),'\n$','','''')
execute "set rtp+=" . g:opamshare . "/merlin/vim"

" Pathogen bundle manager
runtime bundle/vim-pathogen/autoload/pathogen.vim 
call pathogen#infect('bundle/{}', '~/src/shrc/pkg/vim/.vim/bundle/{}')
call pathogen#helptags()

" Indention and Syntax
syntax on
filetype plugin indent on
set noautoindent
set nosmartindent
set nocindent

" Autocomplete confirm for coc
" https://github.com/neoclide/coc.nvim/wiki/Completion-with-sources#use-cr-to-confirm-completion
inoremap <expr> <cr> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
" https://github.com/neoclide/coc.nvim/wiki/Completion-with-sources#use-tab-or-custom-key-for-trigger-completion
" use <tab> to trigger completion and navigate to the next complete item
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"

let g:tabby_keybinding_accept = '<PageDown>'

let g:elm_format_autosave = 1

let g:pymode_python = 'python3'

let g:ale_fix_on_save = 1

let NERDTreeHijackNetrw=1

" Terraform Settings
let g:terraform_align = 1
let g:terraform_fold_sections = 1
let g:terraform_fmt_on_save = 1

" Disable hclfmt terraform formatting
let g:tf_fmt_autosave = 0

let g:nix_fmt_autosave = 1

set foldmethod=syntax
" Don't screw up folds when inserting text that might affect them, until
" leaving insert mode. Foldmethod is local to the window. Protect against
" screwing up folding when switching between windows.
" autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
" autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif

" Colorscheme Selection
if !has("gui_running")
    if &term == "screen-256color" || &term == "xterm-256color" || &term == "alacritty" || &term == "tmux-256color" || &term == "xterm-kitty"
        set background=dark
        let g:jellybeans_use_term_italics = 1
        colors jellybeans

        highlight clear SignColumn
        call gitgutter#highlight#define_highlights()
    else
        colors default
    endif
else
    set background=dark
    let g:jellybeans_use_term_italics = 1
    colorscheme jellybeans
endif

set backspace=indent,eol,start
set ttyfast
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab

" Enable cursor crosshair
set number
set ruler
set cursorline
set cursorcolumn

let g:indentLine_char = '|'

let g:lightline = {
            \"colorscheme": "wombat",
            \"active": {
            \   "left": [ [ 'mode', 'paste'],
            \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
            \ },
            \ "component": {
            \ },
            \ "component_function": {
            \   "gitbranch": "FugitiveHead",
            \ },
            \ }

" Always show status line
set laststatus=2
set noshowmode

nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>

"set fenc
"
" Only do this part when compiled with support for autocommands.
if has("autocmd")
    autocmd FileType vim set expandtab

    au BufRead,BufNewFile *.tpl.html set filetype=html

    autocmd FileType bash,sh set expandtab tabstop=2 shiftwidth=2

    autocmd FileType python set expandtab tabstop=4 shiftwidth=4

    " Web Devel Stuff
    "autocmd Filetype html setlocal makeprg=tidy\ -quiet\ -e\ %
    "autocmd Filetype php,html exe 'setlocal equalprg=tidy\ -quiet\ -i\ -f\ '.&errorfile
    " For JSON
    " autocmd FileType json setl expandtab equalprg=json_reformat
    autocmd FileType json setl expandtab tabstop=2 softtabstop=2 shiftwidth=2

    " for CSS, also have things in braces indented:
    autocmd FileType css setl expandtab tabstop=4 shiftwidth=4
    " for HTML, generally format text, but if a long line has been created
    " leave it alone when editing:
    autocmd FileType html setl expandtab tabstop=4 softtabstop=4 shiftwidth=4

    " for Jade template files
    autocmd FileType jade setl expandtab tabstop=2 softtabstop=2 shiftwidth=2

    " for YAML files
    autocmd FileType yaml setl expandtab tabstop=2 softtabstop=2 shiftwidth=2

    " for Markdown files
    autocmd FileType markdown setl textwidth=80

    " for Terraform files
    autocmd FileType tf setl expandtab tabstop=2 softtabstop=2 shiftwidth=2

    " for both CSS and HTML, use genuine tab characters for 
    " indentation, to make files a few bytes smaller:
    autocmd FileType html,css,php setl expandtab

    autocmd FileType javascript setl expandtab tabstop=2 softtabstop=2 shiftwidth=2
    autocmd FileType typescript setl expandtab tabstop=4 softtabstop=4 shiftwidth=4

    " setting for go
    autocmd Filetype go setl noexpandtab tabstop=4 softtabstop=4 shiftwidth=4 noautoindent
    " autocmd Filetype go autocmd BufWritePre <buffer> Fmt

    autocmd Filetype conf setl expandtab tabstop=4 softtabstop=4 shiftwidth=4 noautoindent

    " setting for nginx config files
    autocmd FileType nginx setl expandtab tabstop=4 softtabstop=4 shiftwidth=4

    " setting for Earthfile
    autocmd Filetype Earthfile setl expandtab tabstop=4 softtabstop=4 shiftwidth=4

    " Enable file type detection.
    " Use the default filetype settings, so that mail gets 'tw' set to 72,
    " 'cindent' is on in C files, etc.
    " Also load indent files, to automatically do language-dependent indenting.
    " filetype plugin indent on

    " Put these in an autocmd group, so that we can delete them easily.
    " augroup vimrcEx
    " au!

    " For all text files set 'textwidth' to 78 characters.
    " autocmd FileType text setlocal textwidth=78

    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event handler
    " (happens when dropping a file on gvim).
    " Also don't do it when the mark is in the first line, that is the default
    " position when opening a file.
    autocmd BufReadPost *
                \ if line("'\"") > 1 && line("'\"") <= line("$") |
                \   exe "normal! g`\"" |
                \ endif

    " augroup END

else
    set autoindent		" always set autoindenting on
endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
    command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                \ | wincmd p | diffthis
endif

"This doesn't inline
let html_use_css = 1

function! TmpHtml(line1, line2)
    exec a:line1.','.a:line2.'TOhtml'
    write! ~/.tmp/temp.html
    bd!
endfunction

function! NumberToggle()
    if(&number == 1)
        set number!
        set relativenumber
    else
        set norelativenumber
        set number
    endif
endfunc

nnoremap mn :call NumberToggle()<cr>

function! DivHtml(line1, line2)
    exec a:line1.','.a:line2.'TOhtml'
    "remove everything up to <body>
    %g/<\/head>/normal $dgg
    "Change Body to <div>
    %s/<body\(.*\)>\n/<div class="vim_block"\1>/
    "Replace the ending it </div>
    %s/<\/body>\n<\/html>/<\/div>
    "remove all <br> tags
    %s/<br>//g

    write! ~/.tmp/temp.html
    bd!

    set nonu
endfunction
command -range=% TmpHtml :call TmpHtml(<line1>,<line2>)
command -range=% DivHtml :call DivHtml(<line1>,<line2>)

" Save a file when forgetting to open with sudo
cmap w!! w !sudo tee >/dev/null %

" Set Leader
let mapleader=","

" jj to exit insert mode
inoremap jj <ESC>

noremap ; :

noremap \ :s/
" noremap = :%s/

noremap mw gq80l

noremap <Space> @q

" Window Navigation
nnoremap <C-H> <C-W>h
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-L> <C-W>l

" Directory Navigation
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>
