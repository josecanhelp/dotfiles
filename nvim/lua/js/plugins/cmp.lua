--------------------------------------------------------------------------------
-- nvim-cmp: Autocompletion
--------------------------------------------------------------------------------
return {
    'hrsh7th/nvim-cmp',
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "L3MON4D3/LuaSnip", -- LuaSnip should be listed here
        "saadparwaiz1/cmp_luasnip"
    },
    config = function()
        local cmp = require 'cmp'
        local luasnip = require 'luasnip'

        local function tab_complete()
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                cmp.complete()
            end
        end

        local function s_tab_complete()
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                cmp.complete()
            end
        end

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert({
                ['<Tab>'] = cmp.mapping(tab_complete, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(s_tab_complete, { 'i', 's' }),
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
            }),
            sources = cmp.config.sources({
                { name = 'luasnip' },
            }, {
                { name = 'buffer' },
            })
        })
    end
}
