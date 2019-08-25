syntax on
filetype plugin on
set background=dark
set guifont=InputMono:h14
set clipboard=unnamed " yanked content is copied to the clipboard
colorscheme spacegray
set number " Enable line numbers
set cursorline " Highlight current line
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch " Highlight searches
set ignorecase " Ignore case of search
set incsearch " Highlight dynamically as pattern is typed
set showmode " Show the current mode
set autowrite  " Save on buffer switch
set mouse=a " Enable mouse scroll

let g:netrw_liststyle=3

let g:NERDSpaceDelims = 1 " Add spaces after comment delimiters by default
let g:NERDCompactSexyComs = 1 "  Use compact syntax for prettified multi-line comments
let g:NERDDefaultAlign = 'left' " Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDAltDelims_java = 1 " Set a language to use its alternate delimiters by default
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } } " Add your own custom formats or override the defaults
let g:NERDCommentEmptyLines = 1 " Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDTrimTrailingWhitespace = 1 " Enable trimming of trailing whitespace when uncommenting
 
" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","
let g:mapleader = ","

" Fast saves
nmap <leader>w :w!<cr>

" Down is really the next line
nnoremap j gj
nnoremap k gk

"Easy escaping to normal model
imap jj <esc>

set rtp+=/usr/local/opt/fzf
set tags=~/Code/Tighten/LaraSells/php.tags

" How many lines of the files should be visible while scrolling up or down?
set scrolloff=7

let g:ackprg = 'ag --nogroup --nocolor --column'

" CtrlP Stuff

" Familiar commands for file/symbol browsing
map <D-p> :CtrlP<cr>
"map <C-r> :CtrlPBufTag<cr>

" I don't want to pull up these folders/files when calling CtrlP
set wildignore+=*/vendor/**

" Open splits
nmap vs :vsplit<cr>
nmap sp :split<cr>

nmap <C-b> :NERDTreeToggle<cr>

" Quickly go forward or backward to buffer
nmap :bp :BufSurfBack<cr>
nmap :bn :BufSurfForward<cr>

map <C-n> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
