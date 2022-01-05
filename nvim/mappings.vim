" ------------------------------------------------------------------------------
" ** Mappings **
" File: ~/dotfiles/nvim/mappings.vim
" Author: Jose Soto <josecanhelp@gmail.com>
" Source: https://github.com/josecanhelp/dotfiles
" # Keymapping Mode Legend
"     n - Normal
"     v - Visual and Select
"     s - Select
"     x - Visual
"     o - Operator-pending
"     i - Insert
"     l - Insert, Command-line, Lang-Arg
"     c - Command-line
"     Ne - Normal, Visual, Select, Operator-pending
"
"     [nvsxoilc]noremap - Don't recursively map if recursive mapping is on (default)
"     [nvsxoilc]map
"     [nvsxoilc]unmap
"     [nvsxoilc]mapclea
" -----------------------------------------------------------------------------

" Set the leader to be the spacebar
let mapleader = "\<Space>"

" Source vimrc
nnoremap <Leader>r :source $MYVIMRC<CR>

" Escape to normal mode
imap jj <esc>
cnoremap jj <C-c>

" Toggle the cursor line highlighting
nnoremap <Leader>h :set cursorline!<CR>

" Clear the highlighted search results
nnoremap <Leader><space> :noh<CR>

" Set or unset the vertical highlight
nnoremap <Leader>v :set cuc<CR>
nnoremap <Leader><space>v :set nocuc<CR>

" Move highlighted text
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Console Log Helper
vnoremap L yoconsole.log('<ESC>pa: ', <ESC>pa);<ESC>
augroup LogHelperMappings
    au!
    au FileType php vnoremap L yodd('<ESC>pa: ', <ESC>pa);<ESC>
    au FileType js, jsx, ts, tsx vnoremap L yoconsole.log('<ESC>pa: ', <ESC>pa);<ESC>
augroup END

" Y yanks from the cursor to the end of line as expected. See :help Y.
nnoremap Y y$

" D deletes to the end of the line
nnoremap D d$

" Split windows
nnoremap <leader>vs :vsplit<cr>
nnoremap <leader>sp :split<cr>

" Repeat macros for all selected lines
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
function! ExecuteMacroOverVisualRange()
    echo '@'.getcmdline()
    execute ":'<,'>normal @".nr2char(getchar())
endfunction

" Edit Train Your Keyboard files
nnoremap <Leader><Leader>kb :EditKBMappers<CR>

" Quickly append semicolon or comma
inoremap ;; <Esc>A;<Esc>
inoremap ,, <Esc>A,<Esc>

" Smooth Scrolling
noremap <silent> <c-u> :call smooth_scroll#up(&scroll, 20, 2)<CR>
noremap <silent> <c-d> :call smooth_scroll#down(&scroll, 20, 2)<CR>
noremap <silent> <c-b> :call smooth_scroll#up(&scroll*2, 20, 4)<CR>
noremap <silent> <c-f> :call smooth_scroll#down(&scroll*2, 20, 4)<CR>

" Allow easy navigation between wrapped lines.
vmap j gj
vmap k gk
nmap j gj
nmap k gk

" Traverse through buffers
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Mappings: commentary
nnoremap <Leader>ci :Commentary<CR>
vnoremap <Leader>ci :Commentary<CR>

" Mappings: fern
nnoremap <Leader>e :Fern . -drawer -toggle<CR>
nnoremap <C-n> :Fern . -drawer<CR>
nnoremap <Leader>E :Fern .<CR>
function! FernLocalMappings()
    nnoremap <buffer><nowait> l <Plug>(fern-action-expand)
    nnoremap <buffer><nowait> h <Plug>(fern-action-collapse)
    nnoremap <buffer><nowait> s <Plug>(fern-action-hidden-toggle)
    nnoremap <buffer><nowait> b <Plug>(fern-action-leave)
    nnoremap <buffer><nowait> <CR> <Plug>(fern-action-open)
    nnoremap <buffer><nowait> v <Plug>(fern-action-open:rightest)<C-w><C-p>
    nnoremap <buffer><nowait> o <Plug>(fern-action-open:system)
    nnoremap <buffer><nowait> f <Plug>(fern-action-new-file)
    nnoremap <buffer><nowait> d <Plug>(fern-action-new-dir)
    nnoremap <buffer><nowait> - <Plug>(fern-action-mark-toggle)
    nnoremap <buffer><nowait> r <Plug>(fern-action-rename)
    nnoremap <buffer><nowait> c <Plug>(fern-action-copy)
    nnoremap <buffer><nowait> m <Plug>(fern-action-move)
    nnoremap <buffer><nowait> y <Plug>(fern-action-clipboard-copy)
    nnoremap <buffer><nowait> x <Plug>(fern-action-clipboard-move)
    nnoremap <buffer><nowait> p <Plug>(fern-action-clipboard-paste)
    nnoremap <buffer><nowait> D <Plug>(fern-action-trash)
    nnoremap <buffer><nowait> g? <Plug>(fern-action-help:all)
endfunction

" Mappings: fugitive
nnoremap<Leader>g :Gedit :<CR>

" Mappings: maximizer
nnoremap <leader>o :MaximizerToggle<CR>
vnoremap <leader>o :MaximizerToggle<CR>gv

" Mappings: phpactor
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

" Mappings: sourcery
function! SourceryMappings()
    nmap <buffer> gp <Plug>SourceryGoToRelatedPluginDefinition
    nmap <buffer> gm <Plug>SourceryGoToRelatedMappings
    nmap <buffer> gc <Plug>SourceryGoToRelatedConfig
endfunction

" Mapping: telescope
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
nnoremap <leader>fm <cmd>lua require('telescope.builtin').marks()<cr>
nnoremap <Leader>H <Cmd>Telescope help_tags<CR>
nnoremap <Leader>so <Cmd>Telescope sourcery<CR>
nnoremap <Leader>do <Cmd>Telescope dotfiles<CR>
nnoremap <Leader><Leader>t <Cmd>Telescope<CR>

" Mappings: test
" nmap <Leader>rt :TestToggleStrategy<CR>
nmap <Leader>rs :TestSuite<CR>
nmap <Leader>rf :TestFile<CR>
nmap <Leader>rl :TestLast<CR>
nmap <Leader>rn :TestNearest<CR>
nmap <Leader>rv :TestVisit<CR>
nnoremap <Leader>rt :<C-U>call RunTestFileInDockerCompose()<CR>
function! RunTestFileInDockerCompose()
    let filename = expand("%:t:r")
    execute ":Dispatch ./devops test-functional --filter=" . filename
endfunction

" Mappings: vdebug
nnoremap <Leader>B :Breakpoint<CR>
nnoremap <Leader>V :VdebugStart<CR>

" Mappings: lsp
nnoremap gD <cmd>lua vim.lsp.buf.declaration()<cr>
nnoremap gd <cmd>lua vim.lsp.buf.definition()<cr>
nnoremap K <cmd>lua vim.lsp.buf.hover()<cr>
nnoremap gi <cmd>lua vim.lsp.buf.implementation()<cr>
" noremap D <cmd>lua vim.lsp.buf.type_definition()<cr>
nnoremap <leader>f <cmd>lua vim.lsp.buf.formatting()<CR>
vnoremap <leader>F <cmd>lua vim.lsp.buf.range_formatting()<CR>
nnoremap <leader>k <cmd>lua vim.lsp.buf.document_symbol()<CR>
noremap <leader>ld <cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>
nnoremap <leader>q <cmd>lua vim.lsp.diagnostic.set_loclist()<CR>

" Snippet
" Mappings: ultisnips
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
let g:UltiSnipEditSplit = "<s->"

function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction
