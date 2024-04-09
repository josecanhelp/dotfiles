--------------------------------------------------------------------------------
-- Telescope: Highly extendable fuzzy finders
--------------------------------------------------------------------------------

local builtin = require_on_exported_call('telescope.builtin')

return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-live-grep-args.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    'nvim-telescope/telescope-ui-select.nvim',
  },
  cmd = {
    'Telescope',
  },
  keys = {
    { '<Leader>ff',        builtin.git_files,                                                               desc = 'Telescope Git Files' },
    { '<Leader>fa',        builtin.find_files,                                                              desc = 'Telesscope All Files' },
    { '<Leader>fb',        builtin.buffers,                                                                 desc = 'Telescope Buffers' },
    { '<Leader>fh',        builtin.oldfiles,                                                                desc = 'Telescope History' },
    { '<Leader>s',         builtin.lsp_document_methods,                                                    desc = 'Telescope LSP Methods' },
    { '<Leader>S',         builtin.lsp_document_symbols,                                                    desc = 'Telescope LSP Symbols' },
    { '<Leader>l',         builtin.current_buffer_fuzzy_find,                                               desc = 'Telescope Current Buffer Lines' },
    { '<Leader>C',         builtin.commands,                                                                desc = 'Telescope Commands' },
    { '<Leader>:',         builtin.command_history,                                                         desc = 'Telescope Command History' },
    { '<Leader>R',         builtin.pickers,                                                                 desc = 'Telescope Resume' },
    { '<Leader><Leader>f', builtin.filetypes,                                                               desc = 'Telescope Filetypes' },
    { '<Leader><Leader>t', builtin.builtin,                                                                 desc = 'Telescope Builtin Pickers' },
    { '<Leader>fg',        function() require('telescope').extensions.live_grep_args.live_grep_args() end,  desc = 'Telescope Live Grep Args' }
  },
  config = function()
    local telescope = require('telescope')
    local actions = require('telescope.actions')

    telescope.setup {
      defaults = {
        prompt_prefix = '  ',
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
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
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
            }
          }
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
              ["<C-x>"] = "delete_buffer",
            }
          }
        },
      },
      extensions = {
        live_grep_args = {
          prompt_title = 'Live Ripgrep',
          mappings = {
            i = {
              ["<C-k>"] = require('telescope-live-grep-args.actions').quote_prompt(),
            }
          }
        }
      },
    }

    telescope.load_extension('fzf')
    telescope.load_extension('live_grep_args')
    telescope.load_extension('ui-select')
  end
}
