--------------------------------------------------------------------------------
-- Neovim configuration
--------------------------------------------------------------------------------
-- Generated into ~/.config/nvim/init.lua by home-manager. Plugins come from
-- nix/home/nvim.nix, so there is no plugin manager and no :TSInstall.
-- Editing this file requires `darwin-rebuild switch` to take effect.

-- Leader must be set before any mapping that uses it.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--------------------------------------------------------------------------------
-- Disable unused built-in plugins (startup time)
--------------------------------------------------------------------------------
-- netrw is deliberately NOT disabled. Without nvim-tree it is the only file
-- browser left, and disabling it makes :Ex silently do nothing.
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1

--------------------------------------------------------------------------------
-- General options
--------------------------------------------------------------------------------
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.hidden = true
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.autoread = true
vim.opt.confirm = true
vim.opt.encoding = 'utf-8'
-- unnamedplus, not unnamed: on macOS `unnamed` maps to the * register while
-- `unnamedplus` maps to +, which is what reliably syncs with the system
-- clipboard.
vim.opt.clipboard = 'unnamedplus'
vim.opt.backspace = { 'indent', 'eol', 'start' }
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'
vim.opt.showmode = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.fillchars = { vert = ' ' }
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.mouse = 'a'
vim.opt.scrolloff = 5
vim.opt.updatetime = 1000
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'noselect' }
vim.opt.wrap = false
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.exrc = true
vim.opt.secure = true

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------
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

-- Commentary
vim.keymap.set('n', '<Leader>ci', ':Commentary<CR>', { silent = true })
vim.keymap.set('v', '<Leader>ci', ':Commentary<CR>', { silent = true })

-- Y yanks from the cursor to the end of line as expected
vim.keymap.set('n', 'Y', 'y$')

-- D deletes to the end of the line
vim.keymap.set('n', 'D', 'd$')

-- Split windows
vim.keymap.set('n', '<Leader>vs', ':vsplit<CR>')
vim.keymap.set('n', '<Leader>sp', ':split<CR>')

-- Allow easy navigation between wrapped lines
vim.keymap.set({ 'v', 'n' }, 'j', 'gj')
vim.keymap.set({ 'v', 'n' }, 'k', 'gk')

-- Traverse through buffers
vim.keymap.set('n', '<Leader>bn', ':bnext<CR>')
vim.keymap.set('n', '<Leader>bp', ':bprevious<CR>')
vim.keymap.set('n', '<Leader>bd', ':bdelete<CR>')

-- Quick append semicolon or comma
vim.keymap.set('i', ';;', '<Esc>A;<Esc>')
vim.keymap.set('i', ',,', '<Esc>A,<Esc>')

--------------------------------------------------------------------------------
-- Briefly highlight yanked text
--------------------------------------------------------------------------------
-- Carried over from the deleted globals.lua, which used the now-deprecated
-- vim.highlight.on_yank. vim.hl.on_yank is the current API; both exist in
-- Neovim 0.12.4 but only one of them will keep existing.
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_on_yank', { clear = true }),
  callback = function()
    vim.hl.on_yank({
      higroup = 'IncSearch',
      timeout = 300,
      on_macro = true,
    })
  end,
})

--------------------------------------------------------------------------------
-- Colorscheme
--------------------------------------------------------------------------------
require('gruvbox').setup({})
vim.o.background = 'dark'
vim.cmd([[colorscheme gruvbox]])

--------------------------------------------------------------------------------
-- Treesitter
--------------------------------------------------------------------------------
-- nvim-treesitter 0.10 in nixpkgs is the `main` branch rewrite. It REMOVED
-- the `nvim-treesitter.configs` module, so the familiar
-- `require('nvim-treesitter.configs').setup { highlight = { enable = true } }`
-- fails with "module 'nvim-treesitter.configs' not found" and aborts the
-- whole init chunk. The rewrite also no longer enables highlighting itself.
--
-- Instead, start treesitter per buffer. pcall means filetypes with no
-- installed parser silently fall back to regex highlighting rather than
-- erroring, which matters because only 16 grammars are installed.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter_start', { clear = true }),
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

--------------------------------------------------------------------------------
-- Guess indent
--------------------------------------------------------------------------------
require('guess-indent').setup({})

--------------------------------------------------------------------------------
-- Telescope
--------------------------------------------------------------------------------
local telescope = require('telescope')
local actions = require('telescope.actions')

telescope.setup({
  defaults = {
    prompt_prefix = '  ',
    sorting_strategy = 'ascending',
    layout_config = {
      prompt_position = 'top',
    },
    mappings = {
      i = {
        ['<Esc>'] = actions.close,
        ['<C-a>'] = actions.toggle_all,
        ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
      },
    },
    file_ignore_patterns = {
      'node_modules',
      '.DS_Store',
      '.git/',
      'resources/dist',
      'storage/framework',
    },
  },
  pickers = {
    git_files = {
      mappings = {
        i = {
          ['<C-k>'] = actions.move_selection_previous,
          ['<C-j>'] = actions.move_selection_next,
        },
      },
    },
    find_files = {
      prompt_title = 'All Files',
      no_ignore = true,
      hidden = true,
    },
    current_buffer_fuzzy_find = {
      prompt_title = 'Current Buffer Lines',
    },
    oldfiles = {
      prompt_title = 'History',
    },
    buffers = {
      mappings = {
        i = {
          ['<C-x>'] = 'delete_buffer',
        },
      },
    },
  },
})

telescope.load_extension('fzf')

-- Plain require, not the old require_on_exported_call. That helper lived in
-- globals.lua, which this migration deletes.
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<Leader>ff', builtin.git_files, { desc = 'Telescope Git Files' })
vim.keymap.set('n', '<Leader>fa', builtin.find_files, { desc = 'Telescope All Files' })
vim.keymap.set('n', '<Leader>fb', builtin.buffers, { desc = 'Telescope Buffers' })
vim.keymap.set('n', '<Leader>fh', builtin.oldfiles, { desc = 'Telescope History' })
-- live_grep, not live_grep_args: that extension is not among the nine plugins.
vim.keymap.set('n', '<Leader>fg', builtin.live_grep, { desc = 'Telescope Live Grep' })
vim.keymap.set('n', '<Leader>l', builtin.current_buffer_fuzzy_find, { desc = 'Telescope Current Buffer Lines' })
vim.keymap.set('n', '<Leader>C', builtin.commands, { desc = 'Telescope Commands' })
vim.keymap.set('n', '<Leader>:', builtin.command_history, { desc = 'Telescope Command History' })
vim.keymap.set('n', '<Leader>R', builtin.pickers, { desc = 'Telescope Resume' })
vim.keymap.set('n', '<Leader><Leader>f', builtin.filetypes, { desc = 'Telescope Filetypes' })
vim.keymap.set('n', '<Leader><Leader>t', builtin.builtin, { desc = 'Telescope Builtin Pickers' })
