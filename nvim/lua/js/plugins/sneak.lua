--------------------------------------------------------------------------------
-- Vim Sneak
-- Jump to any location specified by two characters.
-- https://github.com/justinmk/vim-sneak
--------------------------------------------------------------------------------

return {
    'justinmk/vim-sneak',
    init = function()
        vim.api.nvim_set_var('sneak#label', 1)
    end,
}
