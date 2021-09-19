local lspconfig = require('lspconfig')

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
