return {
    "vim-test/vim-test",
    config = function()
        vim.g['test#strategy'] = 'vimux'

        -- Define key mappings for vim-test
        local map = vim.api.nvim_set_keymap
        local opts = { noremap = true, silent = true }
        map('n', '<leader>tf', '<cmd>TestFile<CR>', opts)
        map('n', '<leader>tn', '<cmd>TestNearest<CR>', opts)
        map('n', '<leader>tl', '<cmd>TestLast<CR>', opts)
    end
}
