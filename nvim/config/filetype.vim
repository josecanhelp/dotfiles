" ------------------------------------------------------------------------------
" # Filetype Settings
" ------------------------------------------------------------------------------
augroup framework_filetype_settings
  autocmd!
  autocmd BufRead,BufNewFile *.blade.php setlocal commentstring={{--\ %s\ --}}
  autocmd BufRead,BufNewFile *.antlers.html setlocal commentstring={{#\ %s\ #}}
  autocmd FileType scss setl iskeyword+=@-@
augroup END

