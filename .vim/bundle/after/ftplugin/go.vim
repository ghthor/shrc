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

nmap <Leader>s <Plug>(go-implements)
nmap <Leader>i <Plug>(go-info)

nmap <Leader>gd <Plug>(go-doc)
nmap <Leader>gv <Plug>(go-doc-vertical)
nmap <Leader>gb <Plug>(go-doc-browser)

nmap <leader>r <Plug>(go-run)
nmap <leader>b <Plug>(go-build)
nmap <leader>t <Plug>(go-test)
nmap <leader>c <Plug>(go-coverage)

nmap <Leader>de <Plug>(go-def)
nmap <Leader>ds <Plug>(go-def-split)
nmap <Leader>dv <Plug>(go-def-vertical)
nmap <Leader>dt <Plug>(go-def-tab)

nmap <Leader>e <Plug>(go-rename)
