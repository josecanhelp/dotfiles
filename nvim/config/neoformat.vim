" ------------------------------------------------------------------------------
" # Neoformat Config
" ------------------------------------------------------------------------------

let g:neoformat_php_phpcsfixer = {
  \ 'exe': 'php-cs-fixer',
  \ 'args': ['fix', '-q', '--config', '.php-cs-fixer.dist.php'],
  \ 'replace': 1,
  \ }

let g:neoformat_enabled_php = ['phpcsfixer']
let g:neoformat_enabled_javascript = ['prettier']

" ------------------------------------------------------------------------------
" # Register Neoformat On Save
" ------------------------------------------------------------------------------

" augroup neoformat_on_save
"   autocmd!
"   autocmd BufWritePre *.php,*.js,*.vue undojoin | Neoformat
" augroup END
