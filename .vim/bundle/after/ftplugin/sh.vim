let b:ale_fixers = ['shfmt']
let b:shfmt_extra_args = '-i 2'
let b:shfmt_fmt_on_save = 0

nnoremap <leader>r :!%:p
nnoremap <leader>n :exec '!'.getline('.')
nnoremap <leader>m :read'!'.getline('.')
