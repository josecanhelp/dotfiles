" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'git://github.com/ajh17/Spacegray.vim'
" Initialize plugin system
call plug#end()

syntax on
filetype plugin on
set omnifunc=syntaxcomplete#Completeset background=dark
set guifont=InputMono:h14
set clipboard=unnamed " yanked content is copied to the clipboard
colorscheme spacegray
set number " Enable line numbers
set cursorline " Highlight current line
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
hi CursorLine   cterm=NONE ctermbg=lightblue ctermfg=white guibg=lightblue guifg=white

let g:NERDTreeShowHidden=1
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

" Toggle the cursor line highlighting
nnoremap <Leader>h :set cursorline!<CR>

" Down is really the next line
nnoremap j gj
nnoremap k gk

" Easy escaping to normal model
imap jj <esc>

set rtp+=/usr/local/opt/fzf
set tags=.git/tags

" How many lines of the files should be visible while scrolling up or down?
set scrolloff=7

let g:ackprg = 'ag --nogroup --nocolor --column'

" FZF as fuzzy file searcher with ctrl+p
map <C-p> :FZF<cr>

" I don't want to pull up these folders/files when calling FZF
set wildignore+=*/vendor/**

" Open splits
nmap vs :vsplit<cr>
nmap sp :split<cr>

map <C-n> :NERDTreeToggle<CR>


autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" YouCompleteMe
let g:ycm_filetype_specific_completion_to_disable = {
  \ 'php': 1
\}


" Ale Linting
let g:ale_sign_column_always = 1
let g:ale_linters = {
\   'php': ['tlint']
\}

" Phpactor
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
let g:phpactorPhpBin = 'php'
let g:phpactorBranch = 'master'
let g:phpactorOmniAutoClassImport = v:true
autocmd FileType php setlocal omnifunc=phpactor#Complete
let g:phpactorOmniError = v:true

" Repeat macros for all selected lines
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
" end repeat macros for all selected lines

" Put these lines at the very end of your vimrc file.
" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL
