" ------------------------------------------------------------------------------
" # Plugins
" ------------------------------------------------------------------------------
" Human readable vim startup time profiling
" Plug 'tweekmonster/startuptime.vim', {'on': 'StartupTime'}

" FZF
Plug '/usr/local/opt/fzf'

" Peek into registers
Plug 'junegunn/vim-peekaboo'

" https://github.com/ap/vim-css-color
Plug 'ap/vim-css-color'

" https://github.com/christoomey/vim-tmux-navigator
Plug 'christoomey/vim-tmux-navigator'

" https://github.com/edkolev/tmuxline.vim
" Plug 'edkolev/tmuxline.vim'

" https://github.com/alok/notational-fzf-vim
Plug 'https://github.com/alok/notational-fzf-vim'

" https://github.com/itchyny/lightline.vim
Plug 'itchyny/lightline.vim'

" https://github.com/vim-test/vim-test
" Plug 'vim-test/vim-test'
Plug '/Users/jose/Code/JoseCanHelp/vim-test'

" Snippets
Plug 'SirVer/ultisnips'

" https://github.com/jesseleite/vim-sourcery
Plug 'jesseleite/vim-sourcery'

" https://github.com/junegunn/goyo.vim
" Plug 'junegunn/goyo.vim'

" https://github.com/justinmk/vim-sneak
Plug 'justinmk/vim-sneak'

" File system explorer
" https://github.com/lambdalisue/fern.vim
Plug 'lambdalisue/fern.vim'

" Make Fern the default file explorer instead of Netrw
" https://github.com/lambdalisue/fern-hijack.vim
" Plug 'lambdalisue/fern-hijack.vim'

" Make nerdfont available
" https://github.com/lambdalisue/nerdfont.vim
Plug 'lambdalisue/nerdfont.vim'

" Use nerdfont to render Fern
" https://github.com/lambdalisue/fern-renderer-nerdfont.vim
Plug 'lambdalisue/fern-renderer-nerdfont.vim'
" Plug 'antoinemadec/FixCursorHold.nvim'

" Neovim LSP
" Plug 'neovim/nvim-lspconfig'
Plug '/Users/jose/Code/JoseCanHelp/nvim-lspconfig/'

" Auto completion
Plug 'hrsh7th/nvim-compe'
"
" https://github.com/ludovicchabant/vim-gutentags
" Plug 'ludovicchabant/vim-gutentags'

" https://github.com/tjdevries/nlua.nvim
Plug 'tjdevries/nlua.nvim'

" https://github.com/phpactor/phpactor
Plug 'phpactor/phpactor', {'for': 'php', 'do': 'composer install --no-dev -o'}

" Syntax highlighting for a bunch of languages
" https://github.com/tree-sitter/tree-sitter
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
Plug 'nvim-treesitter/playground'

" Fallback for languages without good treesitter implementations
" https://github.com/sheerun/vim-polyglot
Plug 'sheerun/vim-polyglot'

" https://github.com/szw/vim-maximizer
Plug 'szw/vim-maximizer'

" https://github.com/terryma/vim-smooth-scroll
Plug 'terryma/vim-smooth-scroll'

" https://github.com/tmsvg/pear-tree
Plug 'tmsvg/pear-tree'

" Code commenting
" https://github.com/tpope/vim-commentary
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
" Plug 'nvim-lua/popup.nvim'

" https://github.com/nvim-lua/plenary.nvim
Plug 'nvim-lua/plenary.nvim'

" Telescope fuzzy finder
" https://github.com/nvim-telescope/telescope.nvim
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
" Plug 'fhill2/telescope-ultisnips.nvim'

" Momentary yank highlighting
Plug 'machakann/vim-highlightedyank'

" Indent on paste
" https://github.com/sickill/vim-pasta
Plug 'sickill/vim-pasta'

" Fuzzy Finder
" https://github.com/junegunn/fzf.vim
Plug 'junegunn/fzf.vim'

" Place, toggle and display marks
" https://github.com/kshenoy/vim-signature
Plug 'kshenoy/vim-signature'

" Replaces git-gutter
" https://github.com/mhinz/vim-signify
Plug 'mhinz/vim-signify'

" HTML/CSS expand abbreviation magic
" Plug 'mattn/emmet-vim'

Plug 'https://github.com/josecanhelp/vim-clarity'

" Closing tag annotations
Plug 'code-biscuits/nvim-biscuits'

Plug 'sbdchd/neoformat'
Plug 'skywind3000/asyncrun.vim'

" Plug 'jesseleite/vim-tinkeray'

Plug '/Users/jose/Code/JoseCanHelp/vim-tinkeray'

Plug 'github/copilot.vim'
Plug 'tpope/vim-rhubarb'

" ------------------------------------------------------------------------------
" # Quick Configs
" ------------------------------------------------------------------------------
" Config: pear-tree
 let g:pear_tree_ft_disabled = ["TelescopePrompt"]

" Config: highlightedyank
let g:highlightedyank_highlight_duration = 1000

" Config: signify
let g:signify_sign_add = '┃'
let g:signify_sign_change = '┃'

hi SignifySignAdd ctermbg=none ctermfg=green
hi SignifySignChange ctermbg=none ctermfg=yellow
hi SignifySignDelete ctermbg=none ctermfg=red
"
" Config: ultisnips
let g:UltiSnipsSnippetsDir = "~/.config/nvim/UltiSnips"
