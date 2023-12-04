let g:lightline = {
  \ 'mode_map': {
      \ 'n' : 'N',
      \ 'i' : 'I',
      \ 'R' : 'R',
      \ 'v' : 'V',
      \ 'V' : 'VL',
      \ "\<C-v>": 'VB',
      \ 'c' : 'C',
      \ 's' : 'S',
      \ 'S' : 'SL',
      \ "\<C-s>": 'SB',
      \ 't': 'T',
      \ },
  \ 'colorscheme': 'powerline',
  \ 'inactive': {
  \ 'left': [ [ 'mode', 'paste' ],
    \ [ 'fugitive', 'readonly', 'relativepath', 'modified' ] ],
   \ 'right': [ [ 'percent' ], [ 'filetype' ] ],
  \ },
  \ 'active': {
  \ 'left': [ [ 'mode', 'paste' ],
    \ [ 'fugitive', 'readonly', 'relativepath', 'modified' ] ],
   \ 'right': [ [ 'percent' ], [ 'filetype' ] ],
  \ },
  \ 'component_function': {
    \ 'fugitive': 'LightLineFugitive',
    \ 'readonly': 'LightLineReadonly',
    \ 'modified': 'LightLineModified',
  \   'filename': 'LightlineFilename',
  \ },
  \ 'separator': { 'left': '', 'right': '' },
  \ 'subseparator': { 'left': '⮁', 'right': '|' }
\ }

function! LightLineModified()
  if &filetype == "help"
    return ""
  elseif &modified
    return "+"
  elseif &modifiable
    return ""
  else
    return ""
  endif
endfunction

function! LightlineFilename()
  let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
  let modified = &modified ? ' +' : ''
  return filename . modified
endfunction

function! LightLineReadonly()
  if &filetype == "help"
    return ""
  elseif &readonly
    return "⭤"
  else
    return ""
  endif
endfunction

function! LightLineFugitive()
  return exists('*fugitive#head') ? fugitive#head() : ''
endfunction
