" ------------------------------------------------------------------------------
" # Filetype Settings
" ------------------------------------------------------------------------------
augroup framework_filetype_settings
  autocmd!
  autocmd BufRead,BufNewFile *.blade.php setlocal commentstring={{--\ %s\ --}}
  autocmd BufRead,BufNewFile *.antlers.html setlocal commentstring={{#\ %s\ #}}
  autocmd FileType scss setl iskeyword+=@-@
augroup END

" auto format rust files
au BufEnter *.rs if !exists('b:ale_fix_on_save') | let b:ale_fix_on_save = 1 | endif

