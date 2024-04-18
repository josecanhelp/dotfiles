require('js.disable')
require('js.globals')
require('js.options')
require('js.keymaps')

-- Ensure lazy.nvim plugin manager is installed
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- Init lazy.nvim and let it handle everything in my plugins module
require('lazy').setup('js.plugins', {
  ui = { border = 'rounded' },
  change_detection = { notify = false },
})
