" ------------------------------------------------------------------------------
" # Plugins
" ------------------------------------------------------------------------------
" Human readable vim startup time profiling
Plug 'tweekmonster/startuptime.vim', {'on': 'StartupTime'}
" FZF
Plug '/usr/local/opt/fzf'
" https://github.com/ap/vim-css-color
Plug 'ap/vim-css-color'
" https://github.com/christoomey/vim-tmux-navigator
Plug 'christoomey/vim-tmux-navigator'
" https://github.com/edkolev/tmuxline.vim
Plug 'edkolev/tmuxline.vim'
" https://github.com/alok/notational-fzf-vim
Plug 'https://github.com/alok/notational-fzf-vim'
" https://github.com/itchyny/lightline.vim
Plug 'itchyny/lightline.vim'
" https://github.com/vim-test/vim-test
Plug 'janko/vim-test'
" https://github.com/jesseleite/vim-sourcery
Plug 'jesseleite/vim-sourcery'
" https://github.com/junegunn/goyo.vim
Plug 'junegunn/goyo.vim'
" https://github.com/justinmk/vim-sneak
Plug 'justinmk/vim-sneak'
" https://github.com/lambdalisue/fern-renderer-nerdfont.vim
Plug 'lambdalisue/fern-renderer-nerdfont.vim', {'on': 'Fern'}
" File system explorer
" https://github.com/lambdalisue/fern.vim
Plug 'lambdalisue/fern.vim', {'on': 'Fern'}
" https://github.com/lambdalisue/nerdfont.vim
Plug 'lambdalisue/nerdfont.vim'
" https://github.com/ludovicchabant/vim-gutentags
Plug 'ludovicchabant/vim-gutentags'
" https://github.com/tjdevries/nlua.nvim
Plug 'tjdevries/nlua.nvim'
" Neovim LSP
" https://github.com/neovim/nvim-lspconfig
Plug 'neovim/nvim-lspconfig'
" https://github.com/phpactor/phpactor
Plug 'phpactor/phpactor', {'branch': 'develop', 'for': 'php', 'do': 'composer install --no-dev -o'}
" Syntax highlighting for a bunch of languages
" https://github.com/sheerun/vim-polyglot
Plug 'sheerun/vim-polyglot',
" https://github.com/szw/vim-maximizer
Plug 'szw/vim-maximizer'
" https://github.com/terryma/vim-smooth-scroll
Plug 'terryma/vim-smooth-scroll'
" https://github.com/tmsvg/pear-tree
Plug 'tmsvg/pear-tree'
" Code commenting - https://github.com/tpope/vim-commentary
Plug 'tpope/vim-commentary'
" Run commands in the background asynchronously
" vim-test is using this as the test runner
" https://github.com/tpope/vim-dispatch
Plug 'tpope/vim-dispatch'
" https://github.com/tpope/vim-fugitive
Plug 'tpope/vim-fugitive'
" https://github.com/tpope/vim-surround
Plug 'tpope/vim-surround'
" https://github.com/vim-vdebug/vdebug
Plug 'vim-vdebug/vdebug', {'on': ['Breakpoint', 'VdebugStart']}
" https://github.com/wellle/targets.vim 
Plug 'wellle/targets.vim' 
" https://github.com/nvim-lua/popup.nvim
Plug 'nvim-lua/popup.nvim'
" https://github.com/nvim-lua/plenary.nvim
Plug 'nvim-lua/plenary.nvim'
" Telescope fuzzy finder
" https://github.com/nvim-telescope/telescope.nvim
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
" Nvim Auto completion
" https://github.com/hrsh7th/nvim-compe
Plug 'hrsh7th/nvim-compe'
" Momentary yank highlighting
Plug 'machakann/vim-highlightedyank'
" Linting
" https://github.com/dense-analysis/ale
Plug 'w0rp/ale'
" Indent on paste
" https://github.com/sickill/vim-pasta
Plug 'sickill/vim-pasta'
" Fuzzy Finder
" https://github.com/junegunn/fzf.vim
Plug 'junegunn/fzf.vim'

" ------------------------------------------------------------------------------
" # Quick Configs
" ------------------------------------------------------------------------------
" Config: pear-tree
 let g:pear_tree_ft_disabled = ["TelescopePrompt"]

" Config: highlightedyank
let g:highlightedyank_highlight_duration = 1000
