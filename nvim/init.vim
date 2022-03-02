call plug#begin('~/.local/share/nvim/site/autoload')
  source ~/.config/nvim/plugins.vim
call plug#end()

call sourcery#init()
call tinkeray#set_sail('redeeem.test')
