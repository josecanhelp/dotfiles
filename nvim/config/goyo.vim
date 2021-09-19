    let g:goyo_linenr=1

    function! s:goyo_enter()
      set lbr
      set wrap
      set spell spelllang=en_us
    endfunction

    function! s:goyo_leave()
      set nolbr
      set nowrap
      set nospell
    endfunction

    autocmd! User GoyoEnter nested call <SID>goyo_enter()
    autocmd! User GoyoLeave nested call <SID>goyo_leave()
"
