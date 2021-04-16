
let test#enabled_runners = ['php#phpunit', 'javascript#mocha']
" let test#strategy = "dispatch"
let test#php#phpunit#executable = 'vendor/bin/phpunit'

let g:test#php#phpunit#options = {
  \ 'nearest': '--no-coverage',
  \ 'file':    '--no-coverage',
  \}

augroup Test
  autocmd!
  autocmd BufNewFile,BufRead *Test.php :compiler phpunit
augroup END

let g:dispatch_compilers = {
  \ './bin/phpunit': 'phpunit',
  \ './vendor/bin/phpunit': 'phpunit',
  \}

let test#strategy = {
  \ 'nearest': 'neovim',
  \ 'file':    'dispatch',
  \ 'suite':   'dispatch',
\}
