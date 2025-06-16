if exists('g:loaded_rep_reg')
  finish
endif
let g:loaded_rep_reg = 1


if !get(g:, 'rep_reg_disable_default_command', 0)
  command! -nargs=1 -complete=customlist,rep_reg#complete EditRegister call rep_reg#edit(<f-args>)
endif
command! -nargs=1 ChangeRegister call rep_reg#change_register(<f-args>)
xnoremap <silent> <Plug>(RepRegEditVisual) :<C-U>call rep_reg#edit_visual(v:register)<CR>

call rep_reg#init()
