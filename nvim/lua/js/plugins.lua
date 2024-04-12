--------------------------------------------------------------------------------
-- Plugins (the ones which don't require any extra config)
--------------------------------------------------------------------------------

-- Short helper for plugins that require lua .setup() call 🤏
local s = function(plugin)
    return { plugin, config = true }
end

return {
    s('nmac427/guess-indent.nvim'), -- Smart indentation width detection
    'tpope/vim-commentary',
    -- 'github/copilot.vim',
    'itchyny/lightline.vim',
    'junegunn/vim-peekaboo',
    'justinmk/vim-sneak',
    'tpope/vim-surround',
    'wellle/targets.vim',
    'christoomey/vim-tmux-navigator',
    'tpope/vim-fugitive',
    -- 'tpope/vim-repeat', -- Better `.` repeat
    -- 'PeterRincker/vim-searchlight', -- Improved search match highlighting
    -- 'jesseleite/vim-noh', -- Auto-clear search highlighting
    -- 'markonm/traces.vim', -- Improved substitute highlighting and previewing
    -- s('windwp/nvim-autopairs'), -- Auto-pair closing brackets, quotes, etc.
    -- s('JoosepAlviste/nvim-ts-context-commentstring'), -- Commentstring detection for embedded languages
}
