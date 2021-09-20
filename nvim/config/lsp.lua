local lspconfig = require('lspconfig')
-- local util = require "lspconfig".util

-- PHP
lspconfig.intelephense.setup{
  init_options = {licenceKey = "00R7CVDYEXOB400"},
}

-- Vue
lspconfig.vuels.setup { }

-- Yaml
lspconfig.yamlls.setup { }

-- Json
lspconfig.jsonls.setup { }

-- Html
lspconfig.html.setup({
  filetypes = {'html', 'blade', 'antlers'}
})

-- local eslint = {
--   lintCommand = "eslint_d -f unix --stdin --stdin-filename ${INPUT}",
--   lintStdin = true,
--   lintFormats = {"%f:%l:%c: %m"},
--   lintIgnoreExitCode = true,
--   formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}",
--   formatStdin = true
-- }

-- require "lspconfig".efm.setup {
--   init_options = {documentFormatting = true},
--   filetypes = {"javascript", "typescript"},
--   root_dir = function(fname)
--     return util.root_pattern("tsconfig.json")(fname) or
--     util.root_pattern(".eslintrc.js", ".git")(fname);
--   end,
--   settings = {
--     rootMarkers = {".eslintrc.js", ".git/"},
--     languages = {
--       javascript = {eslint},
--       typescript = {eslint}
--     }
--   }
-- }

local function setup_servers()
  require'lspinstall'.setup()
  local servers = require'lspinstall'.installed_servers()
  for _, server in pairs(servers) do
    require'lspconfig'[server].setup{}
  end
end

setup_servers()

-- Automatically reload after `:LspInstall <server>` so we don't have to restart neovim
require'lspinstall'.post_install_hook = function ()
  setup_servers() -- reload installed servers
  vim.cmd("bufdo e") -- this triggers the FileType autocmd that starts the server
end
