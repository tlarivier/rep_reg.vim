let s:default_special = ['*', '+', '"', '_', '#', '%', '-', '.', ':']
let s:valid_registers = split('abcdefghijklmnopqrstuvwxyz0123456789"+\-*._#%:', '\zs')
let s:readonly_registers = ['=', ':', '/']
let s:register_hints = {
  \ '=': 'Expression register (read-only)',
  \ ':': 'Command-line history (read-only)',
  \ '/': 'Last search pattern (read-only)'
\ }

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
  if !has('clipboard')
    call filter(regs, { _, val -> val !=# '+' && val !=# '*' })
  endif
  return regs
endfunction

function! rep_reg#edit(reg, ...) abort
  let force_reload = a:0 > 0 ? a:1 : 0
  if strlen(a:reg) != 1 || index(s:valid_registers, a:reg) == -1
    echoerr 'EditRegister: Invalid register'
    return
  endif

  if (a:reg ==# '+' || a:reg ==# '*') && !has('clipboard')
    echoerr 'Clipboard register not supported in this Vim build'
    return
  endif

  let readonly = index(s:readonly_registers, a:reg) != -1 && !get(g:, 'rep_reg_force_edit_readonly', 0)
  let existing_buf = -1
  for buf in getbufinfo({'bufloaded': 1})
    if getbufvar(buf.bufnr, 'rep_reg_target', '') ==# a:reg
      let existing_buf = buf.bufnr
      break
    endif
  endfor

  if existing_buf != -1 && !force_reload
    if getbufvar(existing_buf, '&modified')
      let choice = confirm('Register "'.a:reg.'" buffer modified. Reload anyway?', "&Yes\n&No\n&Cancel", 2)
      if choice == 1
        execute 'bdelete! ' . existing_buf
      elseif choice == 2
        execute 'buffer ' . existing_buf
        return
      else
        return
      endif
    else
      execute 'buffer ' . existing_buf
      return
    endif
  endif

  let l:cmd = get({
        \ 'horizontal': 'split',
        \ 'tab':        'tabnew',
        \ 'vertical':   'vsplit',
        \ }, get(g:, 'rep_reg_split', 'vertical'), 'vsplit')
  execute l:cmd . ' | enew'

  execute 'file [rep_reg:' . a:reg . ']'
  setlocal buftype=acwrite bufhidden=wipe noswapfile
  if !get(g:, 'rep_reg_buflisted', 1)
    setlocal nobuflisted
  endif
  setlocal filetype=rep_reg

  let l:reg_content = []
  try
    let l:reg_content = getreg(a:reg, 1, 1)
  catch /^Vim\%((\a\+)\)\=:E/ " catch getreg() error
    echohl ErrorMsg
    echomsg 'Cannot read register "' . a:reg . '": ' . v:exception
    echohl None
    return
  endtry

  if empty(l:reg_content)
    let l:reg_content = ['']
  endif

  if readonly
    call setline(1, l:reg_content)
    setlocal nomodifiable readonly
  else
    call setline(1, l:reg_content)
  endif

  let b:rep_reg_target = a:reg
  let b:rep_reg_readonly = readonly

  augroup rep_reg_autocmds
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call rep_reg#save()
    autocmd BufUnload,BufDelete,QuitPre <buffer> call rep_reg#check_modified_on_unload()
    autocmd BufDelete <buffer> unlet! b:rep_reg_target b:rep_reg_readonly
  augroup END

  setlocal nomodified
  redraw | echo 'Editing register "' . a:reg . '"'
endfunction

function! rep_reg#list_buffers() abort
  echomsg 'Open rep_reg buffers:'
  for buf in getbufinfo({'bufloaded': 1})
    if has_key(buf.variables, 'rep_reg_target')
      echom '- ' . buf.name . ' => "' . getreg(buf.variables.rep_reg_target) . '"'
    endif
  endfor
endfunction

function! rep_reg#list() abort
  let results = []
  for buf in getbufinfo({'bufloaded': 1})
    if has_key(buf.variables, 'rep_reg_target')
      call add(results, {'bufnr': buf.bufnr, 'reg': buf.variables.rep_reg_target, 'content': getreg(buf.variables.rep_reg_target)})
    endif
  endfor
  return results
endfunction

function! rep_reg#save() abort
  if !exists('b:rep_reg_target')
    echoerr 'rep_reg#save: No target register set.'
    return
  endif
  if exists('b:rep_reg_readonly') && b:rep_reg_readonly
    echoerr 'rep_reg#save: Cannot save read-only register.'
    return
  endif

  let l:content = getline(1, '$')
  call setreg(b:rep_reg_target, l:content)
  echohl ModeMsg
  echomsg 'Register "' . b:rep_reg_target . '" updated.'
  echohl None
  setlocal nomodified
endfunction

function! rep_reg#check_modified_on_unload() abort
  if exists('b:rep_reg_target') && &modified
    if get(g:, 'rep_reg_save_on_leave', 0)
      call rep_reg#save()
    else
      echohl WarningMsg
      echomsg 'Register "' . b:rep_reg_target . '" has unsaved changes.'
      echohl None
    endif
  endif
endfunction

function! rep_reg#complete(A, L, P) abort
  return filter(copy(s:valid_registers), { _, val -> val =~ '^' . a:A })
endfunction

function! rep_reg#edit_visual(reg) range
  let selection = getline(a:firstline, a:lastline)
  call setreg(a:reg, selection)
  call rep_reg#edit(a:reg)
endfunction

function! rep_reg#change_register(newreg) abort
  if strlen(a:newreg) != 1 || index(s:valid_registers, a:newreg) == -1
    echoerr 'Invalid register: ' . a:newreg
    return
  endif
  if !exists('b:rep_reg_target')
    echoerr 'No current register in buffer.'
    return
  endif
  call rep_reg#save()
  let b:rep_reg_target = a:newreg
  call rep_reg#edit(a:newreg)
endfunction
