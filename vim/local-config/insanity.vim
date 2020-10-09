syntax on

filetype plugin on
" Save on buffer switch
set autowrite  
set background=dark
set backspace=indent,eol,start
" yanked content is copied to the clipboard
set clipboard=unnamed 
set expandtab
" Highlight searches
set hlsearch 
" Ignore case of search
set ignorecase 
" Highlight dynamically as pattern is typed
set incsearch 
" Enable mouse scroll
set mouse=a 
" Highlight current line
set cursorline 

set noswapfile
" Do not wrap the end of the line
set nowrap 
" Enable line numbers
set number 
" Make the line numbers display relative numbers
set norelativenumber 

set shiftwidth=4
" Show the current mode
set noshowmode 
" Open new files in horizontal splits to the bottom
set splitbelow 
" Open new files in vertical splits to the right
set splitright 

set tabstop=4
" Ignore these folders during fuzzy search
set wildignore+=*/vendor/** 

" Ignore these folders during fuzzy search
set wildignore+=*/node_modules/** 

set runtimepath+=/usr/local/opt/fzf

" Add padding to the bottom of the file
set scrolloff=7 

set laststatus=2

set ttyfast 

set synmaxcol=210 " Do not process syntax on really long lines

" Persistent undo
set undofile
set undodir=$HOME/.vim_undo//

" keep X lines of command history
set history=500

" if an open file changes while loaded in a buffer, update the buffer with the
" file contents
set autoread

" when joining lines, if both lines are commented, delete the comment token
" from the beginning of the line being joined
set formatoptions+=j

" when incrementing and decremeting numbers (Ctrl-A / Ctrl-X), don't assume
" " numbers that start with 0 are octal. Treat them as base 10.
set nrformats-=octal
