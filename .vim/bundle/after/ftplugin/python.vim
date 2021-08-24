" let b:ale_python_pylint_options = '--indent-string="  "'
let b:ale_python_pylint_auto_indent_string = 1

nnoremap <leader>c :!mypy --py2 --ignore-missing-imports %:p
