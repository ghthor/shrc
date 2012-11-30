set nocompatible
set noedcompatible

set hidden

" Pathogen bundle manager
runtime bundle/vim-pathogen/autoload/pathogen.vim 
call pathogen#infect()

" Indention and Syntax
syntax on
filetype plugin indent on
set noautoindent
set nosmartindent
set nocindent

" Go Fmt via syntastic on write
let g:syntastic_go_checker_option_gofmt_write = 1

set foldmethod=syntax
" Don't screw up folds when inserting text that might affect them, until
" leaving insert mode. Foldmethod is local to the window. Protect against
" screwing up folding when switching between windows.
" autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
" autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif

" Colorscheme Selection
if !has("gui_running")
    if &term == "xterm-256color"
        set t_Co=256
        " feel free to choose :set background=light for a different style
        set background=dark
        colors peaksea
    else
        colorscheme ron
    endif
endif

set backspace=indent,eol,start
set ttyfast
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set smarttab

set number
set ruler
set cursorline
set cursorcolumn
set statusline=(%f,%{strlen(&ft)?&ft:'?'},%{&fenc},%{&ff},%{fugitive#statusline()})\ \ %-9.(%l,%c%V%)\ \ %<%P
" Always show status line
set laststatus=2


nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

"set fenc
"
" Only do this part when compiled with support for autocommands.
if has("autocmd")
    au BufRead,BufNewFile *.tpl.html set filetype=html

    " Web Devel Stuff
    "autocmd Filetype html setlocal makeprg=tidy\ -quiet\ -e\ %
    "autocmd Filetype php,html exe 'setlocal equalprg=tidy\ -quiet\ -i\ -f\ '.&errorfile
    " For JSON
    autocmd FileType json set equalprg=json_reformat

    " for CSS, also have things in braces indented:
    autocmd FileType css setl expandtab tabstop=4 shiftwidth=4
    " for HTML, generally format text, but if a long line has been created
    " leave it alone when editing:
    autocmd FileType html setl expandtab tabstop=4 softtabstop=4 shiftwidth=4

    " for Jade template files
    autocmd FileType jade setl expandtab tabstop=2 softtabstop=2 shiftwidth=2

    " for both CSS and HTML, use genuine tab characters for 
    " indentation, to make files a few bytes smaller:
    autocmd FileType html,css,php setl expandtab

    " setting for go
    autocmd Filetype go setl noexpandtab tabstop=4 softtabstop=4 shiftwidth=4 noautoindent
    " autocmd Filetype go autocmd BufWritePre <buffer> Fmt


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

" jj to exit insert mode
inoremap jj <ESC>
