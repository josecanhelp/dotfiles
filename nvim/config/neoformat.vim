" ------------------------------------------------------------------------------
" # Neoformat Config
" ------------------------------------------------------------------------------

let g:neoformat_php_phpcsfixer = {
  \ 'exe': 'php-cs-fixer',
  \ 'args': ['fix', '-q', '--config', '.php-cs-fixer.dist.php'],
  \ 'replace': 1,
  \ }

let g:neoformat_enabled_php = ['phpcsfixer']

" ------------------------------------------------------------------------------
" # Register Neoformat On Save
" ------------------------------------------------------------------------------

augroup neoformat_on_save
  autocmd!
  autocmd BufWritePre *.php undojoin | Neoformat
augroup END
