-- Highlight briefly on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_on_yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank {
      higroup = 'IncSearch',
      timeout = 300,
      on_macro = true
    }
  end
})

vim.o.background = "dark"

vim.cmd([[colorscheme gruvbox]])
