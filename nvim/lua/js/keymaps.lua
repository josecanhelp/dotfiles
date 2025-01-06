-- Set the leader to be the spacebar
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Source vimrc
vim.keymap.set('n', '<Leader>r', ':source $MYVIMRC<CR>')

-- Escape to normal mode
vim.keymap.set('i', 'jj', '<esc>')
vim.keymap.set('c', 'jj', '<C-c>')

-- Toggle the cursor line highlighting
vim.keymap.set('n', '<Leader>h', ':set cursorline!<CR>')

-- Clear the highlighted search results
vim.keymap.set('n', '<Leader><space>', ':noh<CR>')

-- Set or unset the vertical highlight
vim.keymap.set('n', '<Leader>v', ':set cuc<CR>')
vim.keymap.set('n', '<Leader><space>v', ':set nocuc<CR>')

-- Move highlighted text
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- Normal mode mapping for Commentary
vim.keymap.set('n', '<Leader>ci', ':Commentary<CR>', { silent = true })

-- Visual mode mapping for Commentary
vim.keymap.set('v', '<Leader>ci', ':Commentary<CR>', { silent = true })

vim.keymap.set('n', '<Leader>g', ':Gedit :<CR>')
vim.keymap.set('n', '<Leader>gp', ':Git pull<CR>')

-- Console Log Helper
-- For different file types, use autocmds to set mappings conditionally
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = "php",
    callback = function()
        vim.keymap.set('v', 'L', "yodd('<ESC>pa: ', <ESC>pa);<ESC>", { buffer = true })
    end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "javascript", "jsx", "typescript", "tsx" },
    callback = function()
        vim.keymap.set('v', 'L', "yoconsole.log('<ESC>pa: ', <ESC>pa);<ESC>", { buffer = true })
    end,
})

-- Y yanks from the cursor to the end of line as expected.
vim.keymap.set('n', 'Y', 'y$')

-- D deletes to the end of the line
vim.keymap.set('n', 'D', 'd$')

-- Split windows
vim.keymap.set('n', '<Leader>vs', ':vsplit<CR>')
vim.keymap.set('n', '<Leader>sp', ':split<CR>')

-- Allow easy navigation between wrapped lines.
vim.keymap.set({ 'v', 'n' }, 'j', 'gj')
vim.keymap.set({ 'v', 'n' }, 'k', 'gk')

-- Traverse through buffers
vim.keymap.set('n', '<Leader>bn', ':bnext<CR>')
vim.keymap.set('n', '<Leader>bp', ':bprevious<CR>')
vim.keymap.set('n', '<Leader>bd', ':bdelete<CR>')

-- Quick append semicolon or comma
vim.keymap.set('i', ';;', '<Esc>A;<Esc>')
vim.keymap.set('i', ',,', '<Esc>A,<Esc>')

-- Mapping for telescope
-- vim.keymap.set('n', '<Leader>fa', "<cmd>lua require('telescope.builtin').find_files()<cr>")
-- vim.keymap.set('n', '<Leader>ff', "<cmd>lua require('telescope.builtin').git_files()<cr>")
-- vim.keymap.set('n', '<Leader>fg', "<cmd>lua require('telescope.builtin').live_grep()<cr>")
-- vim.keymap.set('n', '<Leader>fb', "<cmd>lua require('telescope.builtin').buffers()<cr>")
-- vim.keymap.set('n', '<Leader>fH', "<cmd>lua require('telescope.builtin').help_tags()<cr>")
-- vim.keymap.set('n', '<Leader>fh', "<cmd>lua require('telescope.builtin').project_history()<cr>")
-- vim.keymap.set('n', '<Leader>fm', "<cmd>lua require('telescope.builtin').marks()<cr>")
-- vim.keymap.set('n', '<Leader>k', "<cmd>lua require('telescope.builtin').lsp_document_symbols()<cr>")
-- vim.keymap.set('n', '<Leader>K', "<cmd>lua require('telescope.builtin').lsp_code_actions()<cr>")
-- vim.keymap.set('n', '<Leader>l', "<cmd>lua require('telescope.builtin').builtin()<cr>")

-- LSP Mappings
vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
vim.keymap.set('n', '<leader>ld', '<cmd>lua vim.diagnostic.open_float()<CR>')
vim.keymap.set('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>')
vim.keymap.set('n', '<leader>o', "<cmd>lua require('maximize').toggle()<CR>")

-- nvim-tree mappings
vim.keymap.set('n', '<leader>e', ":NvimTreeToggle<CR>")
