noremap mt :!go test<CR>
noremap mit :!go test -run=Integration<CR>
noremap mut :!go test -run=Unit<CR>

" Default SuperTab to omnifunc completion for Go files
" <c-x><c-n> - Keyword
" <c-x><c-f> - Filepath
" <c-x><c-u> - User Defined
" <c-x><c-o> - Onmi
let g:SuperTabDefaultCompletionType = '<c-x><c-o>'
