" ------------------------------------------------------------------------------
" # Fern Settings
" ------------------------------------------------------------------------------

let g:fern#renderer = "nerdfont"
" let g:fern#disable_default_mappings = 1
let g:fern#default_hidden = 1
"
function! s:init_fern() abort
  nmap <silent> <buffer> <C-n> :<C-u>FernDo close<CR>
endfunction

augroup fern-custom
  autocmd! *
  autocmd FileType fern call s:init_fern()
augroup END

" Disable netrw
let g:loaded_netrw             = 1
let g:loaded_netrwPlugin       = 1
let g:loaded_netrwSettings     = 1
let g:loaded_netrwFileHandlers = 1

augroup my-fern-hijack
  autocmd!
  autocmd BufEnter * ++nested call s:hijack_directory()
augroup END

function! s:hijack_directory() abort
  let path = expand('%:p')
  if !isdirectory(path)
    return
  endif
  bwipeout %
  execute printf('Fern %s', fnameescape(path))
endfunction
