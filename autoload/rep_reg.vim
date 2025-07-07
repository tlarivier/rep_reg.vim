let s:save_cpo = &cpo
set cpo&vim

" ============================================================================
" CONFIGURATION MANAGEMENT
" ============================================================================

function! s:config_get() abort
  if !exists('s:config')
    let s:config = extend({
      \ 'split_command':    'split',
      \ 'confirm_readonly': 1,
      \ 'filetype':         'rep_reg',
      \ 'reuse_window':     1
    \ }, get(g:, 'rep_reg_config', {}), 'keep')
  endif
  return s:config
endfunction

" ============================================================================
" REGISTER UTILITIES
" ============================================================================

function! s:reg_buffer_name(reg) abort
  if     a:reg ==# '"'           | return '[Register unnamed]'
  elseif a:reg ==# '*'           | return '[Register primary]' 
  elseif a:reg ==# '+'           | return '[Register clipboard]'
  elseif a:reg ==# '='           | return '[Register expression]'
  elseif a:reg ==# ':'           | return '[Register command]'
  elseif a:reg ==# '/'           | return '[Register search]'
  elseif a:reg =~# '^[0-9]$'     | return '[Register ' . a:reg . ']'
  elseif a:reg =~# '^[a-zA-Z-]$' | return '[Register ' . a:reg . ']'
  else
    throw 'E1234: Invalid register name: ' . string(a:reg)
  endif
endfunction

function! s:reg_is_readonly(reg) abort
  return a:reg =~# '^[:./%#]$'
endfunction

function! s:reg_validate(reg) abort
  if len(a:reg) != 1
    throw 'E1234: Invalid register name: ' . string(a:reg)
  endif
  
  try
    call getreg(a:reg)
  catch /^Vim.*:E354:/
    throw 'E1235: Register not accessible: ' . string(a:reg)
  catch
    throw 'E1234: Invalid register name: ' . string(a:reg)  
  endtry
endfunction

" ============================================================================
" HOOK SYSTEM
" ============================================================================

function! s:hook_call(hook_name, context) abort
  if a:hook_name !~# '^RepReg\(PreEdit\|PostEdit\|PreSave\|PostSave\)$'
    throw 'E1234: Invalid hook name: ' . a:hook_name
  endif
  
  if !exists('*' . a:hook_name)
    return 1
  endif
  
  try
    call call(a:hook_name, [a:context])
    return 1
  catch
    if &verbose >= 2
      echohl ErrorMsg
      echomsg 'rep_reg: Hook ' . a:hook_name . ' failed: ' . v:exception
      echomsg 'Stack: ' . expand('<stack>')
      echohl None
    endif
    return 0
  endtry
endfunction

" ============================================================================
" UI MANAGEMENT
" ============================================================================

function! s:ui_open_buffer(buffer_name, config) abort
  let bufnr = bufnr('^' . escape(a:buffer_name, '[]') . '$')
  
  if bufnr != -1
    let winnr = bufwinnr(bufnr)
    if winnr != -1 && a:config.reuse_window
      execute winnr . 'wincmd w'
      return bufnr
    else
      execute a:config.split_command
      execute 'buffer' bufnr
      return bufnr
    endif
  else
    execute a:config.split_command
    execute 'edit' fnameescape(a:buffer_name)
    return bufnr('%')
  endif
endfunction

" ============================================================================
" BUFFER MANAGEMENT
" ============================================================================

function! s:buf_setup(reg, bufnr, config) abort
  if a:bufnr != -1 && getbufvar(a:bufnr, 'rep_reg_target', '') ==# a:reg
    return
  endif
  
  setlocal buftype=acwrite bufhidden=hide noswapfile noundofile
  execute 'setlocal filetype=' . a:config.filetype
  
  let content = getreg(a:reg)
  let regtype = getregtype(a:reg)
  
  if len(content) > 0
    call setline(1, split(content, "\n", 1))
  endif
  
  setlocal nomodified
  
  let b:rep_reg_target        = a:reg
  let b:rep_reg_original_type = regtype
  let b:rep_reg_readonly      = s:reg_is_readonly(a:reg)
  
  if b:rep_reg_readonly && a:config.confirm_readonly
    echohl WarningMsg
    echomsg 'Warning: Register "' . a:reg . '" is readonly'
    echohl None
  endif
  
  command! -buffer -bang RegSave call rep_reg#save()
  nnoremap <buffer> <C-S> :RegSave<CR>
  
  augroup RepRegBuffer
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call rep_reg#save()
    autocmd BufDelete   <buffer> call rep_reg#cleanup_stale_buffers()
  augroup END
  
  call s:hook_call('RepRegPreEdit', {
    \ 'register': a:reg,
    \ 'content':  content,
    \ 'type':     regtype,
    \ 'readonly': b:rep_reg_readonly
  \ })
endfunction

" ============================================================================
" PUBLIC API - CORE FUNCTIONS
" ============================================================================

function! rep_reg#edit(reg) abort
  call s:reg_validate(a:reg)
  
  let config      = s:config_get()
  let buffer_name = s:reg_buffer_name(a:reg)
  
  let bufnr = s:ui_open_buffer(buffer_name, config)
  
  call s:buf_setup(a:reg, bufnr, config)
  
  call s:hook_call('RepRegPostEdit', {
    \ 'register': get(b:, 'rep_reg_target', ''),
    \ 'buffer':   bufnr('%')
  \ })
endfunction

function! rep_reg#save() abort
  if !exists('b:rep_reg_target')
    echohl ErrorMsg
    echomsg 'rep_reg: Current buffer is not a register buffer'
    echohl None
    return 0
  endif
  
  let reg      = b:rep_reg_target
  let readonly = get(b:, 'rep_reg_readonly', 0)
  
  if readonly
    echohl ErrorMsg  
    echomsg 'rep_reg: Cannot save to readonly register: ' . reg
    echohl None
    return 0
  endif
  
  let lines   = getline(1, '$')
  let content = join(lines, "\n")
  let regtype = get(b:, 'rep_reg_original_type', 'v')
  
  let context = {
    \ 'register': reg,
    \ 'content':  content,
    \ 'type':     regtype,
    \ 'lines':    copy(lines)
  \ }
  
  if !s:hook_call('RepRegPreSave', context)
    return 0
  endif
  
  call setreg(reg, context.content, context.type)
  
  setlocal nomodified
  
  call s:hook_call('RepRegPostSave', extend(context, {
    \ 'success': 1
  \ }))
  
  echo 'Register "' . reg . '" saved (' . len(split(content, "\n")) . ' lines)'
  return 1
endfunction

" ============================================================================
" PUBLIC API - BUFFER QUERIES
" ============================================================================

function! rep_reg#buffers() abort
  let result = []
  
  for bufnr in range(1, bufnr('$'))
    if !bufexists(bufnr) | continue | endif
    
    let reg = getbufvar(bufnr, 'rep_reg_target', '')
    if empty(reg) | continue | endif
    
    call add(result, {
      \ 'bufnr':    bufnr,  
      \ 'register': reg,
      \ 'name':     bufname(bufnr),
      \ 'modified': getbufvar(bufnr, '&modified'),
      \ 'readonly': getbufvar(bufnr, 'rep_reg_readonly', 0)
    \ })
  endfor
  
  return result
endfunction

function! rep_reg#cleanup_stale_buffers() abort
  let active_buffers = rep_reg#buffers()
  let cleaned        = 0
  
  for buf in active_buffers
    if !bufexists(buf.bufnr) || empty(getbufvar(buf.bufnr, 'rep_reg_target'))
      try
        execute 'bwipeout!' buf.bufnr
        let cleaned += 1
      catch
        " Ignore cleanup errors
      endtry
    endif
  endfor
  
  if cleaned > 0 && &verbose
    echomsg 'rep_reg: Cleaned ' . cleaned . ' stale buffers'
  endif
  
  return cleaned
endfunction

" ============================================================================
" PUBLIC API - UI DISPLAY
" ============================================================================

function! rep_reg#show_buffers() abort
  let buffers = rep_reg#buffers()
  
  if empty(buffers)
    echo 'No register buffers found'
    return
  endif
  
  echo printf('%-6s %-10s %-8s %s', 'Buffer', 'Register', 'Status', 'Name')
  echo repeat('-', 50)
  
  for buf in buffers
    let status = buf.readonly ? 'readonly' : (buf.modified ? 'modified' : 'saved')
    echo printf('%-6d %-10s %-8s %s', buf.bufnr, buf.register, status, buf.name)
  endfor
endfunction

" ============================================================================
" PUBLIC API - SESSION MANAGEMENT
" ============================================================================

function! rep_reg#session_save(...) abort
  let session_name = a:0 > 0 ? a:1 : 'default'
  let session_data = {'version': '1.0', 'timestamp': localtime(), 'buffers': {}}
  
  for buf in rep_reg#buffers()
    let session_data.buffers[buf.register] = {
      \ 'content':  join(getbufline(buf.bufnr, 1, '$'), "\n"),
      \ 'type':     getbufvar(buf.bufnr, 'rep_reg_original_type', 'v'),
      \ 'modified': buf.modified,
      \ 'readonly': buf.readonly
    \ }
  endfor
  
  let session_file = expand('~/.vim/rep_reg_' . session_name . '.session')
  try
    call writefile([string(session_data)], session_file)
    echomsg 'rep_reg: Session saved to ' . session_file
    return 1
  catch
    echohl ErrorMsg
    echomsg 'rep_reg: Failed to save session: ' . v:exception  
    echohl None
    return 0
  endtry
endfunction

function! rep_reg#session_restore(...) abort
  let session_name = a:0 > 0 ? a:1 : 'default'
  let session_file = expand('~/.vim/rep_reg_' . session_name . '.session')
  
  if !filereadable(session_file)
    echohl ErrorMsg
    echomsg 'rep_reg: Session file not found: ' . session_file
    echohl None
    return 0
  endif
  
  try
    let session_data = eval(join(readfile(session_file), ''))
    let restored = 0
    
    for [reg, data] in items(session_data.buffers)
      call setreg(reg, data.content, data.type)
      let restored += 1
    endfor
    
    echomsg 'rep_reg: Restored ' . restored . ' registers from session'
    return 1
  catch
    echohl ErrorMsg
    echomsg 'rep_reg: Failed to restore session: ' . v:exception
    echohl None
    return 0
  endtry
endfunction

" ============================================================================
" PUBLIC API - COMPLETION
" ============================================================================

function! rep_reg#complete(ArgLead, CmdLine, CursorPos) abort
  let registers  = ['\"', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
  let registers += ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm']
  let registers += ['n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
  let registers += ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M']
  let registers += ['N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
  let registers += ['+', '*', '=', ':', '/', '.', '%', '#', '-']
  
  return filter(registers, 'v:val =~# "^" . escape(a:ArgLead, "[]")')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

