command! EditKBMappers call EditKBMappers()

function! EditKBMappers()
  execute 'edit ~/.config/karabiner/karabiner.edn '
  execute 'vsplit'
  execute 'edit ~/.hammerspoon/init.lua'
endfunction
