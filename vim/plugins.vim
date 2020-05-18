" ------------------------------------------------------------------------------
" # Installed Plugins
" ------------------------------------------------------------------------------

" On-demand Plugin Loading
" Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
"
" Normal Plugin Loading
Plug '/usr/local/opt/fzf'
Plug 'airblade/vim-gitgutter'
Plug 'git@github.com:morhetz/gruvbox.git'
Plug 'junegunn/fzf.vim'
Plug 'ludovicchabant/vim-gutentags'
Plug 'scrooloose/nerdtree'
Plug 'yuezk/vim-js'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'posva/vim-vue'
Plug 'prettier/vim-prettier', {'do': 'npm install', 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'lumiliet/vim-twig'
Plug 'sheerun/vim-polyglot'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'vim-vdebug/vdebug', {'on': ['Breakpoint', 'VdebugStart']}
Plug 'justinmk/vim-sneak'
Plug 'junegunn/vim-peekaboo'

" ------------------------------------------------------------------------------
" # Plugin Specific Settings
" ------------------------------------------------------------------------------
" Plugin: Prettier
let g:prettier#exec_cmd_path = '~/.nvm/versions/node/v8.16.0/bin/prettier'

" Plugin: Airline / Ale
" Show Ale errors and warnings in Airline status bar
let g:airline#extensions#ale#enabled = 1

" Plugin: Ale
let g:ale_sign_column_always = 1
" let g:ale_linters = {
" \   'php': ['tlint']
" \}

" Plugin: Sneak
let g:sneak#use_ic_scs = 1
let g:sneak#label = 1

" Plugin: Nerdtree
let g:NERDTreeShowHidden=1
let g:NERDSpaceDelims = 1 " Add spaces after comment delimiters by default
let g:NERDCompactSexyComs = 1 "  Use compact syntax for prettified multi-line comments
let g:NERDDefaultAlign = 'left' " Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDAltDelims_java = 1 " Set a language to use its alternate delimiters by default
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } } " Add your own custom formats or override the defaults
let g:NERDCommentEmptyLines = 1 " Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDTrimTrailingWhitespace = 1 " Enable trimming of trailing whitespace when uncommenting

" Plugin: Phpactor
let g:phpactorPhpBin = 'php'
let g:phpactorBranch = 'master'
let g:phpactorOmniAutoClassImport = v:true
let g:phpactorOmniError = v:true
let g:polyglot_disabled = ['jsx']
let g:vim_jsx_pretty_colorful_config = 1

" Plugin: vim-javascript
" Let vim-javascript detect which pre-processors to check for
let g:vue_pre_processors = 'detect_on_enter'
