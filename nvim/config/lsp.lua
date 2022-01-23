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

-- Tailwind
lspconfig.tailwindcss.setup { }
