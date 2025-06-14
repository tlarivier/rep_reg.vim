function! rep_reg#edit(reg) abort
  if strlen(a:reg) != 1
    echoerr 'EditRegister: Register must be a single character.'
    return
  endif

  let valid = split('abcdefghijklmnopqrstuvwxyz0123456789"+-*._#%:', '\zs')
  if index(valid, a:reg) == -1
    echoerr 'EditRegister: Invalid register "' . a:reg . '"'
    return
  endif

  let l:bufname = '__register_' . a:reg . '__'

  for bufnr in range(1, bufnr('$'))
    if bufexists(bufnr) && bufname(bufnr) ==# l:bufname
      execute 'buffer ' . bufnr
      return
    endif
  endfor

  let l:split = get(g:, 'rep_reg_split', 'vertical')
  if l:split ==# 'horizontal'
    split | enew
  elseif l:split ==# 'tab'
    tabnew | enew
  else
    vertical new | enew
  endif

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
  else
    echoerr 'rep_reg#save: No target register set.'
  endif
endfunction
