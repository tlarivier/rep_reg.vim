if exists('g:loaded_rep_reg')
  finish
endif
let g:loaded_rep_reg = 1

command! -nargs=1 -complete=customlist,rep_reg#complete EditRegister call rep_reg#edit(<f-args>)

call rep_reg#init()
