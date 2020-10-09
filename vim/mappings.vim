" -----------------------------------------------------------------------------
" File: ~/dotfiles/vim/mappings.vim
" Description: A configuration file to map a mix of key-chords or
" consecutive key hits to run commands. Some mappings are confined to certain 
" Vim modes. The legend explains which modes the mappings are enabled for.
" Author: Jose Soto <josecanhelp@gmail.com>
" Source: https://github.com/josecanhelp/dotfiles
" -----------------------------------------------------------------------------

" Set the leader to be the spacebar
let mapleader = "\<Space>"

" -----------------------------------------------------------------------------
" # Keymapping Mode Legend
" -----------------------------------------------------------------------------
    " n - Normal
    " v - Visual and Select
    " s - Select
    " x - Visual
    " o - Operator-pending
    " i - Insert
    " l - Insert, Command-line, Lang-Arg
    " c - Command-line
    " None - Normal, Visual, Select, Operator-pending
    "
    " [nvsxoilc]noremap - Don't recursively map if recursive mapping is on (default)
    " [nvsxoilc]map
    " [nvsxoilc]unmap
    " [nvsxoilc]mapclea

" -----------------------------------------------------------------------------
" # Mappings
" -----------------------------------------------------------------------------

" Re-source vimrc
nnoremap <Leader>r :source $MYVIMRC<CR>

" Escape to normal mode
imap jj <esc>
cnoremap jj <C-c>

" Edit the alternate / previously edited file
nmap <Leader>6 <C-^>

" Toggle the cursor line highlighting
nnoremap <Leader>h :set cursorline!<CR>

" Clear the highlighted search results
nnoremap <Leader><space> :noh<CR>

" Delete all buffers
nmap <Leader>bda :bufdo bd <cr>

" Move highlighted text
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Console Log Helper
vnoremap L yoconsole.log('<ESC>pa: ', <ESC>pa);<ESC>

" FZF fuzzy finders
" Plugin: fzf
nmap <Leader>f :GFiles<CR>
nmap <Leader>F :Files<CR>
map <C-p> :Files<cr>
nmap <Leader>m :GFiles?<CR>
nmap <Leader>t :BTags<CR>
nmap <Leader>T :Tags<CR>
nmap <Leader>b :Buffers<CR>
nmap <Leader>l :BLines<CR>
nmap <Leader>L :Lines<CR>
" nmap <Leader>h :PHistory<CR>
nmap <Leader>H :History<CR>
nmap <Leader>: :History:<CR>
nmap <Leader>M :Maps<CR>
nmap <Leader>C :Commands<CR>
nmap <Leader>' :Marks<CR>
" nmap <Leader>s :Filetypes<CR>
nmap <Leader>S :Snippets<CR>
nmap <Leader><Leader>h :Helptags!<CR>

" By default "Y" is the same as "yy", but like "D" is makes sense for "Y" to
" just yank from the cursor to the end of the line.
" nmap Y y$

" format (gq) a file (af)
nmap gqaf :ALEFix<CR>

" Write
map <leader>w <ESC>:w!<CR>

" Quit
map <leader><leader>q <ESC>:q<CR>

" Write and Quit
map <leader>wq <ESC>:wq<CR>

" Split windows
nmap <leader>vs :vsplit<cr>
nmap <leader>sp :split<cr>

" File system explorer
" Plugin: fern
nmap <Leader>e :FernReveal .<CR>
nmap <Leader>E :Fern .<CR>
function! FernLocalMappings()
  nmap <buffer><nowait> l <Plug>(fern-action-expand)
  nmap <buffer><nowait> h <Plug>(fern-action-collapse)
  nmap <buffer><nowait> s <Plug>(fern-action-hidden-toggle)
  nmap <buffer><nowait> b <Plug>(fern-action-leave)
  nmap <buffer><nowait> <CR> <Plug>(fern-action-open)
  nmap <buffer><nowait> v <Plug>(fern-action-open:rightest)<C-w><C-p>
  nmap <buffer><nowait> o <Plug>(fern-action-open:system)
  nmap <buffer><nowait> f <Plug>(fern-action-new-file)
  nmap <buffer><nowait> d <Plug>(fern-action-new-dir)
  nmap <buffer><nowait> - <Plug>(fern-action-mark-toggle)
  nmap <buffer><nowait> r <Plug>(fern-action-rename)
  nmap <buffer><nowait> c <Plug>(fern-action-copy)
  nmap <buffer><nowait> m <Plug>(fern-action-move)
  nmap <buffer><nowait> y <Plug>(fern-action-clipboard-copy)
  nmap <buffer><nowait> x <Plug>(fern-action-clipboard-move)
  nmap <buffer><nowait> p <Plug>(fern-action-clipboard-paste)
  nmap <buffer><nowait> D <Plug>(fern-action-trash)
  nmap <buffer><nowait> go :call FernActionGithubOpen()<CR>
  nmap <buffer><nowait> g? <Plug>(fern-action-help:all)
endfunction

" PHP intelligence
" Plugin: phpactor
augroup PhpactorMappings
  au!
  au FileType php nmap <buffer> <Leader>u :PhpactorImportClass<CR>
  " Include use statement
  au FileType php nmap <Leader>u :call phpactor#UseAdd()<CR>
  " Invoke the context menu
  au FileType php nmap <Leader>mm :call phpactor#ContextMenu()<CR>
  " Invoke the navigation menu
  au FileType php nmap <Leader>nn :call phpactor#Navigate()<CR>
  " Goto definition of class or class member under the cursor
  au FileType php nmap <Leader>d :call phpactor#GotoDefinition()<CR>
  " Goto definition of class or class member under the cursor
  au FileType php nmap <Leader>dv :call phpactor#GotoDefinitionVsplit()<CR>
  " Show brief information about the symbol under the cursor
  au FileType php nmap <Leader>K :call phpactor#Hover()<CR>
  " Transform the classes in the current file
  au FileType php nmap <Leader>tt :call phpactor#Transform()<CR>
  " Generate a new class (replacing the current file)
  au FileType php nmap <Leader>cc :call phpactor#ClassNew()<CR>
  " Extract expression (normal mode)
  au FileType php nmap <silent><Leader>ee :call phpactor#ExtractExpression(v:false)<CR>
  " Extract expression from selection
  au FileType php vmap <silent><Leader>ee :<C-U>call phpactor#ExtractExpression(v:true)<CR>
  " Extract method from selection
  au FileType php vmap <silent><Leader>em :<C-U>call phpactor#ExtractMethod()<CR>
augroup END


" Repeat macros for all selected lines
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
  echo '@'.getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
" end repeat macros for all selected lines

nmap <Leader><Leader>kb :EditKBMappers<CR>

" Run tests
" Plugin: test
nmap <Leader>rt :w<CR>:TestToggleStrategy<CR>
nmap <Leader>rs :w<CR>:TestSuite<CR>
nmap <Leader>rf :w<CR>:TestFile<CR>
nmap <Leader>rl :w<CR>:TestLast<CR>
nmap <Leader>rn :w<CR>:TestNearest<CR>
nmap <Leader>rv :w<CR>:TestVisit<CR>

" Debugger
" Plugin: vdebug
nnoremap <Leader>B :Breakpoint<CR>
nnoremap <Leader>V :VdebugStart<CR>

" Fugitive
nmap <Leader>g :Gedit :<CR>

" Delete Currently Open File and Buffer
" command! DELF :call delete(expand('%')) | bdelete

" Traverse through buffers
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Ale
" Plugin: ale
nnoremap <Leader><Leader>a :ALEToggle<CR>
nnoremap <Leader>if :ALEFix<CR>

" HTML and CSS abbreviation expansion
" Plugin: emmet
imap <C-e> <plug>(emmet-expand-abbr)
nmap ]e <plug>(emmet-move-next)
nmap [e <plug>(emmet-move-prev)

" Quickly append semicolon or comma
imap ;; <Esc>A;<Esc>
imap ,, <Esc>A,<Esc>

" Local: vimrc
nmap <Leader><Leader>v :EditVimrc<CR>
nmap <Leader><Leader>vm :EditVimMappings<CR>
nmap <Leader><Leader>vp :EditVimPlugins<CR>
function! VimrcLocalMappings()
  nnoremap <buffer><nowait> <leader>gc :GoToRelatedVimrcConfig<CR>
  nnoremap <buffer><nowait> <leader>gm :GoToRelatedVimrcMappings<CR>
  nnoremap <buffer><nowait> <leader>gp :GoToRelatedPlugDefinition<CR>
  nnoremap <buffer><nowait> <leader>pg :GoToPluginUrl<CR>
  nnoremap <buffer><nowait> <leader>py :YankPluginUrl<CR>
  nnoremap <buffer><nowait> <leader>pp :PastePluginFromClipboard<CR>
  nnoremap <buffer><nowait> <leader>pi :PlugInstall<CR>
  nnoremap <buffer><nowait> <leader>pu :PlugUpdate<CR>
  nnoremap <buffer><nowait> <leader>pc :PlugClean<CR>
endfunction
