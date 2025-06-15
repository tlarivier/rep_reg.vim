let s:default_special = ['*', '+', '"', '_', '#', '%', '-', '.', ':']
let s:valid_registers = split('abcdefghijklmnopqrstuvwxyz0123456789"+-*._#%:', '\zs')
let s:readonly_registers = ['=', ':', '/', '"', '(', ')']

function! rep_reg#init() abort
  if get(g:, 'rep_reg_enable_mappings', 1)
    call rep_reg#map_registers()
  endif
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

function! rep_reg#check_modified_on_unload() abort
  if &modified && exists('b:rep_reg_target')
    let l:msg = 'Register "' . b:rep_reg_target . '" has unsaved changes. Save?'
    let l:choice = confirm(l:msg, "&Yes\n&No\n&Cancel", 1)
    if l:choice == 1
      call rep_reg#save()
    elseif l:choice == 3
      execute 'bdelete!'
      return
    endif
  endif
endfunction

function! s:is_editable_register(reg) abort
  return index(s:readonly_registers, a:reg) == -1
endfunction

function! rep_reg#edit(reg) abort
  if strlen(a:reg) != 1 || index(s:valid_registers, a:reg) == -1
    echoerr 'EditRegister: Register must be a single valid character.'
    return
  endif

  if !s:is_editable_register(a:reg)
    echoerr 'EditRegister: Register "' . a:reg . '" is read-only or not editable in a buffer.'
    return
  endif

  if a:reg =~# '\u'
    echomsg 'Warning: Editing an uppercase register "' . a:reg . '" may overwrite its lowercase counterpart.'
  endif

  for buf in getbufinfo({'bufloaded': 1})
    if getbufvar(buf.bufnr, 'rep_reg_target', '') ==# a:reg
      execute 'buffer ' . buf.bufnr
      return
    endif
  endfor

  let l:cmd = get({
        \ 'horizontal': 'split',
        \ 'tab':        'tabnew',
        \ 'vertical':   'vsplit',
        \ }, get(g:, 'rep_reg_split', 'vertical'), 'vsplit')
  execute l:cmd . ' | enew'

  execute 'file [rep_reg:' . a:reg . ']'
  setlocal buftype=acwrite bufhidden=wipe noswapfile nobuflisted
  let l:reg_content = getreg(a:reg, 1, 1)
  if empty(l:reg_content)
    let l:reg_content = ['']
  endif
  call setline(1, l:reg_content)

  let b:rep_reg_target = a:reg

  augroup rep_reg_bufwrite
    autocmd!
    autocmd BufWriteCmd <buffer> call rep_reg#save()
    autocmd BufUnload <buffer> call rep_reg#check_modified_on_unload()
  augroup END

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
  if b:rep_reg_target =~# '\u'
    echomsg 'Warning: Saving to uppercase register "' . b:rep_reg_target . '" will append to its lowercase version.'
  endif

  let l:content = getline(1, '$')
  call setreg(b:rep_reg_target, l:content)
  echohl ModeMsg
  echomsg 'Register "' . b:rep_reg_target . '" updated.'
  echohl None
  setlocal nomodified
endfunction

function! rep_reg#complete(A, L, P) abort
  return filter(copy(s:valid_registers), { _, val -> val =~ '^' . a:A })
endfunction
