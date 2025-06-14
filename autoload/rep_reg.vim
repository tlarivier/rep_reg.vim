function! rep_reg#edit(reg) abort
  let l:bufname = '__register_' . a:reg . '__'
  for bufnr in range(1, bufnr('$'))
    if bufexists(bufnr) && bufname(bufnr) == l:bufname
      execute 'buffer ' . bufnr
      return
    endif
  endfor
  vertical new
  execute 'file ' . l:bufname
  setlocal buftype=acwrite bufhidden=wipe noswapfile nobuflisted
  call setline(1, split(getreg(a:reg), "\n"))
  let b:rep_reg_target = a:reg
  setlocal nomodified
endfunction

function! rep_reg#save() abort
  if exists('b:rep_reg_target')
    let l:content = join(getline(1, '$'), "\n")
    call setreg(b:rep_reg_target, l:content)
    echohl ModeMsg
    echomsg 'Register "' . b:rep_reg_target . '" updated.'
    echohl None
    setlocal nomodified
  endif
endfunction
