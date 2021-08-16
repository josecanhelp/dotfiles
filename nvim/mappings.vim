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

" Edit the alternate / previously edited file
nmap <Leader>6 <C-^>

" Toggle the cursor line highlighting
nnoremap <Leader>h :set cursorline!<CR>

" Clear the highlighted search results
nnoremap <Leader><space> :noh<CR>

" Re-Indent the entire file and preserve cursor location
nnoremap <Leader><space>l  gg=G<C-o>

" Move highlighted text
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Console Log Helper
vnoremap L yoconsole.log('<ESC>pa: ', <ESC>pa);<ESC>
augroup LogHelperMappings
  au!
  au FileType php vnoremap L yodd('<ESC>pa: ', <ESC>pa);<ESC>
  au FileType js vnoremap L yoconsole.log('<ESC>pa: ', <ESC>pa);<ESC>
augroup END

" Y yanks from the cursor to the end of line as expected. See :help Y.
nnoremap Y y$

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
" nnoremap gD <cmd>lua vim.lsp.buf.declaration()<cr>
" nnoremap gd <cmd>lua vim.lsp.buf.definition()<cr>
" nnoremap K <cmd>lua vim.lsp.buf.hover()<cr>
" nnoremap gi <cmd>lua vim.lsp.buf.implementation()<cr>
"nnoremap D <cmd>lua vim.lsp.buf.type_definition()<cr>
" nnoremap <leader>f <cmd>lua vim.lsp.buf.formatting()<CR>
" vnoremap <leader>f <cmd>lua vim.lsp.buf.range_formatting()<CR>
" nnoremap <leader>k <cmd>lua vim.lsp.buf.document_symbol()<CR>
"jnoremap <leader>e <cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>
" nnoremap <leader>q <cmd>lua vim.lsp.diagnostic.set_loclist()<CR>

" Mappings: compe
" inoremap <silent><expr> <C-x>     compe#confirm()
" inoremap <silent><expr> <C-Space> compe#complete()
" inoremap <silent><expr> <CR>      compe#confirm('<CR>')
" inoremap <silent><expr> <C-e>     compe#close('<C-e>')

" Mappings: coc
nnoremap <leader>F <Cmd>Format<cr>
" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif
" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>
" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)
" apply autofix to problem on the current line.
nmap <leader>qf  <plug>(coc-fix-current)
nmap <leader>of  <plug>(coc-action-quickfixes)
nnoremap <leader>f  <plug>(coc-action-quickfixes)
" Show all diagnostics.
" nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
" nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
" nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
" nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
" nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
" nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
" nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
" nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

command! -nargs=0 Prettier :CocCommand prettier.formatFile
nmap <Leader>p :Prettier<CR>
