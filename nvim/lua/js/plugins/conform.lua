--------------------------------------------------------------------------------
-- Conform: A code formatter plugin
--------------------------------------------------------------------------------

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { { "prettierd", "prettier" } },
      php = { 'pint' },
      json = { 'fixjson', 'pint' },
      html = { 'htmlbeautifier' },
      sql = { 'sqlfmt' },
      xml = { 'xmlformat' },
      ant = { 'xmlformat' },
    },
    formatters = {
      xmlformat = {
        command = "xmlformat",
        args = { "--blanks", "--indent", "4", "-" },
      }
    },
    format_on_save = {
      lsp_fallback = true,
      timeout_ms = 500
    },
    log_level = vim.log.levels.ERROR,
    notify_on_error = true,
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
