local lspconfig = require("lspconfig")

-- PHP
lspconfig.intelephense.setup({
	init_options = { licenceKey = "00R7CVDYEXOB400" },
})

-- lspconfig.phpactor.setup { }

-- Vue
lspconfig.vuels.setup({})

-- React
-- lspconfig.react.setup { }

-- Yaml
-- lspconfig.yamlls.setup({
-- 	on_attach = on_attach,
-- 	capabilities = capabilities,
-- 	settings = {
-- 		yaml = {
-- 			schemas = require("schemastore").json.schemas(),
-- 			validate = { enable = true },
-- 			customTags = {
-- 				"!Cidr",
-- 				"!Cidr sequence",
-- 				"!And",
-- 				"!And sequence",
-- 				"!If",
-- 				"!If sequence",
-- 				"!Not",
-- 				"!Not sequence",
-- 				"!Equals",
-- 				"!Equals sequence",
-- 				"!Or",
-- 				"!Or sequence",
-- 				"!FindInMap",
-- 				"!FindInMap sequence",
-- 				"!Base64",
-- 				"!Join",
-- 				"!Join sequence",
-- 				"!Ref",
-- 				"!Sub",
-- 				"!Sub sequence",
-- 				"!GetAtt",
-- 				"!GetAZs",
-- 				"!ImportValue",
-- 				"!ImportValue sequence",
-- 				"!Select",
-- 				"!Select sequence",
-- 				"!Split",
-- 				"!Split sequence",
-- 				"!ImportValue",
-- 			},
-- 		},
-- 	},
-- })

-- Json
lspconfig.jsonls.setup({})

-- Html
lspconfig.html.setup({
	filetypes = { "html" },
})

-- Tailwind
-- lspconfig.tailwindcss.setup({
-- 	filetypes = { "html", "blade", "antlers", "vue" },
-- })

-- Clojure/EDN
lspconfig.clojure_lsp.setup({})

-- Clarity
lspconfig.clarity_lsp.setup({})

-- Solidity
lspconfig.solidity_ls.setup({})
