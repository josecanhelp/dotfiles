" ------------------------------------------------------------------------------
" # Sane Defaults
" ------------------------------------------------------------------------------

syntax on
filetype plugin on
filetype indent on
packadd! matchit
map q: :q
set autoread "if an open file changes while loaded in a buffer, update the buffer with the file contents
set autowrite "Save on buffer switch
set backspace=indent,eol,start
set clipboard=unnamed "yanked content is copied to the clipboard
set cursorline "Highlight current line
set expandtab
set formatoptions+=j "when joining lines, if both lines are commented, delete the comment token from the beginning of the line being joined
set history=500 "keep X lines of command history
set hlsearch "Highlight searches
set ignorecase "Ignore case of search
set incsearch "Highlight dynamically as pattern is typed
set laststatus=2 "Always show window statuses, even if there's only one.
set mouse=a "Enable mouse scroll
set nomodeline "Don't parse modelines (google "vim modeline vulnerability").
set noshowmode "Hide the current mode from cmd bar
set noswapfile
set nowrap "Do not wrap the end of the line
set nrformats-=octal "when incrementing and decremeting numbers (Ctrl-A / Ctrl-X), don't assume numbers that start with 0 are octal. Treat them as base 10.
set number "Enable line numbers
set runtimepath+=/usr/local/opt/fzf
set scrolloff=7 "Add padding to the bottom of the file
set shiftwidth=4
set sidescroll=1 "Keep 15 columns next to the cursor when scrolling horizontally.
set sidescrolloff=15
set signcolumn=yes
set smartcase "Case-sensitive search if query uses an uppercase
set splitbelow "Open new files in horizontal splits to the bottom
set splitright "Open new files in vertical splits to the right
set synmaxcol=210 " Do not process syntax on really long lines
set tabstop=4
set ttyfast 
set undodir=$HOME/.nvim_undo/ "Persistent undo
set undofile "Persistent undo
set updatetime=300 "Reduce updatetime from 4000 to 300 to avoid issues with coc.nvim
set wildignore+=*/node_modules/** "Ignore these folders during fuzzy search
set wildignore+=*/vendor/** "Ignore these folders during fuzzy search
" set completeopt=menuone,noselect "compe recommendation

" set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
"
" Automatically resize vim's windows when resizing vim
augroup equalize_windows_on_resize
  autocmd!
  autocmd VimResized * exec "normal \<c-w>="
augroup END

" Remember last cursor position
augroup neovim_last_position
  autocmd!
  autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
    \ |   exe "normal! g`\""
    \ | endif
augroup END
