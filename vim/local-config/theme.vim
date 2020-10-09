" Set the cursorline highlight colors
let &colorcolumn=join(range(82,999),',') " Display a different bg beyond 80 chars

let g:lightline = {
      \ 'colorscheme': 'powerline',
      \ }

colorscheme gruvbox
let g:gruvbox_contrast_dark = 'hard'
let gruvbox_vert_split = 'gray'
