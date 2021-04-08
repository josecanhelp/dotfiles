let g:ale_sign_column_always = 1
let g:ale_sign_error = '!!'
let g:ale_sign_style_error = '!!'
let g:ale_sign_warning = '!'
let g:ale_sign_style_warning = '!'
let g:ale_disable_lsp = 1

let g:ale_linters = {
\ 'php': ['php', 'phpcs', 'phpmd', 'tlint'],
\ 'lua': ['luacheck'],
\ 'yml': ['yamllint'],
\ 'javascript': ['eslint'],
\ 'vue': ['eslint', 'vls'],
\ }

let g:ale_lua_luacheck_options="--ignore hs"
let g:ale_php_phpcs_standard = '~/.phpcs.xml.dist'
let g:ale_php_phpcs_use_global = 1

" NPM Plugin Required for Vue: https://eslint.vuejs.org/user-guide/
let g:ale_fixers = {
\  '*': ['remove_trailing_lines', 'trim_whitespace'],
\ 'php': ['php_cs_fixer'],
\ 'html': ['eslint'],
\ 'javascript': ['eslint'],
\ 'vue': ['eslint'], 
\ }


function! s:fix_php()
if filereadable('.php_cs.dist')
  let b:ale_fix_on_save = 1
endif
endfunction

