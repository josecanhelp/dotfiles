--------------------------------------------------------------------------------
-- Plugins (the ones which don't require any extra config)
--------------------------------------------------------------------------------

-- Short helper for plugins that require lua .setup() call 🤏
local s = function(plugin)
    return { plugin, config = true }
end

return {
    s('nmac427/guess-indent.nvim'), -- Smart indentation width detection
    s('declancm/maximize.nvim'),    -- Toggle maximize window splits in vim
    'tpope/vim-commentary',         -- Detect filetype and automatically convert to comment
    'itchyny/lightline.vim',        -- Status bar
    'junegunn/vim-peekaboo',        -- View contents of registers
    'tpope/vim-surround',
    'wellle/targets.vim',
    'christoomey/vim-tmux-navigator',
    'tpope/vim-fugitive',
    'neovim/nvim-lspconfig',
    'preservim/vimux',
    s('windwp/nvim-autopairs'), -- Auto-pair closing brackets, quotes, etc.
}
