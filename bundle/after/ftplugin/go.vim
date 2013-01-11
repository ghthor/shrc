noremap mt :!go test<CR>
noremap mtr :!go test ./...<CR>
noremap mtp :!go test -print-all<CR>
noremap mit :!go test -run=Integration<CR>
noremap mitr :!go test -run=Integration ./...<CR>
noremap mut :!go test -run=Unit<CR>
noremap mutr :!go test -run=Unit ./...<CR>

" Default SuperTab to omnifunc completion for Go files
" <c-x><c-n> - Keyword
" <c-x><c-f> - Filepath
" <c-x><c-u> - User Defined
" <c-x><c-o> - Onmi
let g:SuperTabDefaultCompletionType = '<c-x><c-o>'

command! -buffer -nargs=0 GoInstall call s:GoInstall()

" go install the package being editted in the current buffer
func! s:GoInstall()
    let popd = getcwd()
    let pushd = expand('%:p:h')

    " pushd
    exec 'lcd ' . fnameescape(pushd)

    !go install -v

    " popd
    exec 'lcd ' . fnameescape(popd)
endfunction
