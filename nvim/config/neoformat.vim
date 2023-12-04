" ------------------------------------------------------------------------------
" # Neoformat Config
" ------------------------------------------------------------------------------

let g:neoformat_php_phpcsfixer = {
  \ 'exe': 'php-cs-fixer',
  \ 'args': ['fix', '-q', '--config', '.php-cs-fixer.dist.php'],
  \ 'replace': 1,
  \ }

let g:neoformat_enabled_php = ['phpcsfixer']
let g:neoformat_enabled_json = ['fixjson']
let g:neoformat_enabled_javascript = ['prettier']
let g:neoformat_enabled_html = ['prettier']
let g:neoformat_enabled_java = ['prettier']

" function! neoformat#formatters#java#prettier() abort
"     return {
"         \ 'exe': 'prettier',
"         \ 'args': ['--write', '%', '--plugin-search-dir', '/Users/jose/Library/pnpm/global/5/.pnpm/prettier-plugin-java@1.6.2'],
"         \ 'replace': 0,
"         \ }
" endfunction

" ------------------------------------------------------------------------------
" # Register Neoformat On Save
" ------------------------------------------------------------------------------

" augroup neoformat_on_save
"   autocmd!
"   autocmd BufWritePre *.php,*.js,*.vue | Neoformat
"   autocmd BufWritePre *.json | Neoformat
" augroup END
