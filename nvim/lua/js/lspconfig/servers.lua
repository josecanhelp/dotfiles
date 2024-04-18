--------------------------------------------------------------------------------
-- Configured Lsp Servers
--------------------------------------------------------------------------------

return {
  intelephense = true,
  html = {
    filetypes = { 'html', 'blade', 'antlers' },
  },
  tailwindcss = true,
  volar = {
    filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
  },
  jsonls = true,
  yamlls = true,
  sqlls = {
    filetypes = { 'sql' }
  },
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = {
          globals = { 'vim', 'Ray', 'hs', 'spoon' },
          disable = { "lowercase-global" },
        },
      },
    },
  },
  vimls = true,
}
