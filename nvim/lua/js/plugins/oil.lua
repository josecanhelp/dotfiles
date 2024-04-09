--------------------------------------------------------------------------------
-- Oil: A file explorer that you can edit like a buffer
--------------------------------------------------------------------------------

return {
  'stevearc/oil.nvim',
  keys = {
    { '<Leader>e', vim.cmd.Oil },
  },
  opts = {
    delete_to_trash = true,
    default_file_explorer = true,
    skip_confirm_for_simple_edits = true,
    show_hidden = true,
    columns = {
      "icon",
      "size",
      "permissions",
    },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
}

