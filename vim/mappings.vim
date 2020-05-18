" ------------------------------------------------------------------------------
" # Mappings
" ------------------------------------------------------------------------------

" Leader
let mapleader = "\<Space>"

" Easy escaping to normal model
" jj or jk 
imap jj <esc>
cnoremap jj <C-c>
imap jk <Esc>
cnoremap jk <C-c>

" Write
nmap <D-s> <Esc>:w<CR>
map <M-s> <Esc>:w<CR>
map <C-s> <Esc>:w<CR>
map <leader>w :w!<cr>

" Fuzzy Finders
nmap <Leader>f :GFiles<CR>

syntax on
filetype plugin on
colorscheme gruvbox
set background=dark
set clipboard=unnamed " yanked content is copied to the clipboard
set number " Enable line numbers
set relativenumber
set nocursorline " Highlight current line
set tabstop=2
set shiftwidth=2
set expandtab
set hlsearch " Highlight searches
set ignorecase " Ignore case of search
set incsearch " Highlight dynamically as pattern is typed
set showmode " Show the current mode
set autowrite  " Save on buffer switch
set mouse=a " Enable mouse scroll
set backspace=indent,eol,start
set splitright " Open new files in vertical splits to the right
set splitbelow " Open new files in horizontal splits to the bottom
set nowrap " Do not wrap the end of the line

" Set the cursorline highlight colors
hi CursorLine cterm=NONE ctermbg=darkyellow ctermfg=white guibg=lightblue guifg=white

" Toggle the cursor line highlighting
nnoremap <Leader>h :set cursorline!<CR>

" Clear the highlighted search results
nnoremap <Leader><space> :noh<CR>

set runtimepath+=/usr/local/opt/fzf
set tags=.git/tags

" How many lines of the files should be visible while scrolling up or down?
set scrolloff=7


" FZF as fuzzy file searcher with ctrl+p
map <C-p> :FZF<cr>

" I don't want to pull up these folders/files when calling FZF
set wildignore+=*/vendor/**

" Open splits
nmap vs :vsplit<cr>
nmap sp :split<cr>

" Plugin: Nerdtree
map <C-n> :NERDTreeToggle<CR>


" Plugin: Phpactor
" Include use statement
nmap <Leader>u :call phpactor#UseAdd()<CR>
" Invoke the context menu
nmap <Leader>mm :call phpactor#ContextMenu()<CR>
" Invoke the navigation menu
nmap <Leader>nn :call phpactor#Navigate()<CR>
" Goto definition of class or class member under the cursor
nmap <Leader>o :call phpactor#GotoDefinition()<CR>
" Show brief information about the symbol under the cursor
nmap <Leader>K :call phpactor#Hover()<CR>
" Transform the classes in the current file
nmap <Leader>tt :call phpactor#Transform()<CR>
" Generate a new class (replacing the current file)
nmap <Leader>cc :call phpactor#ClassNew()<CR>
" Extract expression (normal mode)
nmap <silent><Leader>ee :call phpactor#ExtractExpression(v:false)<CR>
" Extract expression from selection
vmap <silent><Leader>ee :<C-U>call phpactor#ExtractExpression(v:true)<CR>
" Extract method from selection
vmap <silent><Leader>em :<C-U>call phpactor#ExtractMethod()<CR>

autocmd FileType php setlocal omnifunc=phpactor#Complete

" Repeat macros for all selected lines
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
  echo '@'.getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
" end repeat macros for all selected lines
