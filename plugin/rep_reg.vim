if exists('g:loaded_rep_reg')
  finish
endif
let g:loaded_rep_reg = 1

command! -nargs=1 EditRegister call rep_reg#edit(<f-args>)

augroup RegisterEditor
  autocmd!
  autocmd BufWriteCmd __register_*__ call rep_reg#save()
augroup END

let s:special_registers = get(g:, 'rep_reg_extra_registers', ['*', '+', '"', '_', '#', '%', '0'])

if get(g:, 'rep_reg_enable_mappings', 1)
  if !exists('g:rep_reg_map_prefix')
    let g:rep_reg_map_prefix = 'gr'
  endif
  for c in range(char2nr('a'), char2nr('z'))
    let lhs = g:rep_reg_map_prefix . nr2char(c)
    execute 'nnoremap <silent> ' . lhs . ' :call rep_reg#edit("' . nr2char(c) . '")<CR>'
  endfor
  for c in s:special_registers
    let lhs = g:rep_reg_map_prefix . c
    execute 'nnoremap <silent> ' . lhs . ' :call rep_reg#edit("' . c . '")<CR>'
  endfor
endif
