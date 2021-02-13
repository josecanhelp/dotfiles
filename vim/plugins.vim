Plug '/usr/local/opt/fzf'
Plug 'christoomey/vim-tmux-runner'
Plug 'dense-analysis/ale'
Plug 'janko/vim-test'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-peekaboo'
Plug 'justinmk/vim-sneak'
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'
Plug 'lambdalisue/nerdfont.vim'
Plug 'ludovicchabant/vim-gutentags'
Plug 'lumiliet/vim-twig'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'phpactor/phpactor', {'branch': 'develop', 'for': 'php', 'do': 'composer install --no-dev -o'}
Plug 'posva/vim-vue'
Plug 'scrooloose/nerdcommenter'
Plug 'sheerun/vim-polyglot',
Plug 'skywind3000/asyncrun.vim'
Plug 'tmsvg/pear-tree'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'itchyny/lightline.vim'
Plug 'vim-vdebug/vdebug'
Plug 'yuezk/vim-js'
Plug 'junegunn/goyo.vim'
Plug 'mattn/emmet-vim'
Plug 'ap/vim-css-color'
Plug 'edkolev/tmuxline.vim'
Plug 'takac/vim-hardtime'
Plug 'mzlogin/vim-markdown-toc'
Plug 'terryma/vim-smooth-scroll'
Plug 'tommcdo/vim-exchange'
Plug 'wellle/targets.vim' 
Plug 'tpope/vim-dispatch'
Plug 'szw/vim-maximizer'
" Plug 'SirVer/ultisnips'
Plug 'christoomey/vim-tmux-navigator'
Plug 'https://github.com/alok/notational-fzf-vim'
Plug 'yyq123/vim-syntax-logfile'
Plug 'tpope/vim-projectionist'
Plug 'noahfrederick/vim-composer'
Plug 'noahfrederick/vim-laravel'

" Explicit annotation bindings for more accurate go to
let g:explicit_annotation_bindings = {
  \ 'fzf': 'fzf.vim',
  \ 'coc': 'coc.nvim',
  \ 'writable-search': 'writable_search.vim',
  \ 'textobj': 'vim-textobj-user',
  \ 'camel-case-motions': 'CamelCaseMotion',
  \ }

" Plugin: ultisnips
" let g:UltiSnipsSnippetsDir = "~/.vim/ultisnips"

" Disable tmux navigator when zooming the Vim pane
let g:tmux_navigator_disable_when_zoomed = 1
