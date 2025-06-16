if exists('g:loaded_rep_reg')
  finish
endif
let g:loaded_rep_reg = 1

command! -nargs=1       -complete=customlist,rep_reg#complete EditRegister   call rep_reg#edit(<f-args>)
command! -nargs=1 -bang -complete=customlist,rep_reg#complete EditRegister   call rep_reg#edit(<f-args>, <bang>0)
command! -nargs=1       -complete=customlist,rep_reg#complete ChangeRegister call rep_reg#change_register(<f-args>)
command! RepRegBuffers call rep_reg#list_buffers()

xnoremap <silent> <Plug>(RepRegEditVisual) :<C-U>call rep_reg#edit_visual(v:register)<CR>

call rep_reg#init()

