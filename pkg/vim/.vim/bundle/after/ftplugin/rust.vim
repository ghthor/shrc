noremap mtm :!rustc --test -o %.test % && ./%.test<CR>
noremap mtl :!rustc --test lib.rs && ./$(rustc --crate-name lib.rs)<CR>
