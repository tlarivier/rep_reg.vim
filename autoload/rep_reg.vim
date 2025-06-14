let s:default_special = ['*', '+', '"', '_', '#', '%', '-', '.', ':']
let s:valid_registers = split('abcdefghijklmnopqrstuvwxyz0123456789"+-*._#%:', '\zs')

function! rep_reg#init() abort
  call rep_reg#setup_autocmds()
  if get(g:, 'rep_reg_enable_mappings', 1)
    call rep_reg#map_registers()
  endif
endfunction

function! rep_reg#setup_autocmds() abort
  augroup rep_reg_autocmds
    autocmd!
    autocmd BufWriteCmd <buffer> call rep_reg#save()
  augroup END
endfunction

function! rep_reg#map_registers() abort
  let prefix = get(g:, 'rep_reg_map_prefix', 'gr')
  for r in rep_reg#get_mappable_registers()
    execute 'nnoremap <silent> ' . prefix . r . ' :call rep_reg#edit("' . r . '")<CR>'
  endfor
endfunction

function! rep_reg#get_mappable_registers() abort
  let chars = range(char2nr('a'), char2nr('z'))
  if get(g:, 'rep_reg_registers_include_uppercase', 0)
    let chars += range(char2nr('A'), char2nr('Z'))
  endif
  let regs = map(chars, { _, nr -> nr2char(nr) }) + get(g:, 'rep_reg_extra_registers', s:default_special)
  return regs
endfunction

function! rep_reg#edit(reg) abort
  if strlen(a:reg) != 1 || index(s:valid_registers, a:reg) == -1
    echoerr 'EditRegister: Register must be a single valid character.'
    return
  endif

  let l:bufname = '[rep_reg:' . a:reg . ']'
  for buf in getbufinfo({'bufloaded': 1})
    if fnamemodify(buf.name, ':t') ==# l:bufname
      execute 'buffer ' . buf.bufnr
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
  let l:reg_content = split(getreg(a:reg), "\n")
  if empty(l:reg_content)
    let l:reg_content = ['']
  endif
  call setline(1, l:reg_content)
  let b:rep_reg_target = a:reg
  setlocal filetype=rep_reg
  setlocal nomodified
  redraw | echo 'Editing register "' . a:reg . '"'
endfunction

function! rep_reg#save() abort
  if !exists('b:rep_reg_target')
    echoerr 'rep_reg#save: No target register set.'
    return
  endif
  if index(s:valid_registers, b:rep_reg_target) == -1
    echoerr 'rep_reg#save: Invalid target register.'
    return
  endif

  let l:content = join(getline(1, '$'), "\n")
  call setreg(b:rep_reg_target, l:content)
  echohl ModeMsg
  echomsg 'Register "' . b:rep_reg_target . '" updated.'
  echohl None
  setlocal nomodified
endfunction

function! rep_reg#complete(A, L, P) abort
  return filter(copy(s:valid_registers), { _, val -> val =~ '^' . a:A })
endfunction
