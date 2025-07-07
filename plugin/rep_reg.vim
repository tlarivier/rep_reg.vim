if exists('g:loaded_rep_reg') || v:version < 800 || &cp
  finish
endif
let g:loaded_rep_reg = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=1 -complete=customlist,rep_reg#complete EditRegister
      \ call rep_reg#edit(substitute(<q-args>, '\s\+', '', 'g'))

command! RepRegList call rep_reg#show_buffers()

command! -nargs=? RepRegSessionSave call rep_reg#session_save(<q-args>)
command! -nargs=? RepRegSessionRestore call rep_reg#session_restore(<q-args>)
command! RepRegCleanup call rep_reg#cleanup_stale_buffers()

if !get(g:, 'rep_reg_no_default_mappings', 0)
  let s:prefix = get(g:, 'rep_reg_map_prefix', 'gr')
  
  if maparg(s:prefix . 'a', 'n') !=# ''
    echohl WarningMsg
    echomsg 'rep_reg: Mapping conflict detected with ' . s:prefix
    echomsg 'Set g:rep_reg_no_default_mappings=1 to disable default mappings'
    echohl None
  else
    
    for reg in range(char2nr('a'), char2nr('z'))
      let char = nr2char(reg)
      execute printf('nnoremap <silent> %s%s :EditRegister %s<CR>', s:prefix, char, char)
    endfor
    
    for reg in range(0, 9)
      execute printf('nnoremap <silent> %s%d :EditRegister %d<CR>', s:prefix, reg, reg)
    endfor
    
    let special_regs = [
    \ ['"', '"'],
    \ ['+', '+'],
    \ ['*', '*'],
    \ ['/', '/'],
    \ [':', ':'],
    \ ['.', '.'],
    \ ['%', '%'],
    \ ['#', '#']
    \]
    
    for [key, reg] in special_regs
      execute printf('nnoremap <silent> %s%s :EditRegister %s<CR>', s:prefix, key, reg)
    endfor
    
    execute printf('nnoremap <silent> %sl :RepRegList<CR>', s:prefix)
  endif
endif

augroup RepReg
  autocmd!
  autocmd BufWinEnter [Register\ *] if exists('b:rep_reg_target') | 
    \ command! -buffer -bang RegSave call rep_reg#save() |
    \ nnoremap <buffer> <C-S> :RegSave<CR> |
    \ endif
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

