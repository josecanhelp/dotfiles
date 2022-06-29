local lspconfig = require('lspconfig')

-- PHP
lspconfig.intelephense.setup{
  init_options = {licenceKey = "00R7CVDYEXOB400"},
}

-- lspconfig.phpactor.setup { }

-- Vue
lspconfig.vuels.setup { }

-- React
-- lspconfig.react.setup { }

-- Yaml
lspconfig.yamlls.setup { }

-- Json
lspconfig.jsonls.setup { }

-- Html
lspconfig.html.setup({
  filetypes = {'html', 'blade', 'antlers'}
})

-- Tailwind
lspconfig.tailwindcss.setup({
  filetypes = {'html', 'blade', 'antlers', 'vue'}
})

-- Clojure/EDN
lspconfig.clojure_lsp.setup { }

-- Clarity
lspconfig.clarity_lsp.setup { }

-- Solidity
lspconfig.solidity_ls.setup { }
