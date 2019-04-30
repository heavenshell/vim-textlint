" File: textlint.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version: 1.2.0
" WebPage: http://github.com/heavenshell/vim-textlint.
" Description: Vim plugin for TextLint
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

let g:textlint_configs = get(g:, 'textlint_configs', [])
let g:textlint_enable_quickfix = get(g:, 'textlint_enable_quickfix', 0)
let g:textlint_clear_quickfix = get(g:, 'textlint_clear_quickfix', 1)
let g:textlint_callbacks = get(g:, 'textlint_callbacks', {})
let g:textlint_bin = get(g:, 'textlint_bin', '')

let s:root_path = ''

" TODO Not implemented. Support --rules.
if !exists('g:textlint_rules')
  let g:textlint_rues = []
endif

let s:textlint_config = ''
let s:textlint_complete = ['c']

let s:textlint = {}

function! s:get_root_path(srcpath)
  if s:root_path == ''
    let s:root_path = finddir('node_modules', a:srcpath . ';')
    if s:root_path == ''
      return ''
    endif
    let s:root_path = fnamemodify(s:root_path, ':p')
  endif
  return s:root_path
endfunction

function! s:detect_textlint_bin(root_path)
  let textlint = ''
  if executable('textlint') == 0
    let textlint = exepath(a:root_path . '.bin/textlint')
  else
    let textlint = exepath('textlint')
  endif

  return textlint
endfunction

function! s:build_config(root_path, autofix)
  if s:textlint_config == '' && len(g:textlint_configs) > 0
    let s:textlint_config = g:textlint_configs[0]
  endif

  let file = a:autofix ? '%s' : expand('%:p')
  let stdin = a:autofix ? '' : '--stdin --stdin-filename'
  if s:textlint_config == ''
    let config_path = printf(' %s %s --format json ', stdin, file)
  else
    let config_path = printf(' --config=%s%s %s %s --format json ', a:root_path, s:textlint_config, stdin, file)
  endif

  return config_path
endfunction

" Build textlint bin path.
function! s:build_textlink(binpath, configpath)
  let cmd = a:binpath . a:configpath " . '%'
  return cmd
endfunction

function! s:parse_options(args)
  if a:args =~ '-c\s'
    let args = split(a:args, '-c\s')
    if len(args) > 0
      let s:textlint_config = matchstr(args[0],'^\s*\zs.\{-}\ze\s*$')
    endif
  endif
endfunction

function! s:parse(msg)
  let outputs = []
  let file = expand('%:p')
  for k in a:msg
    for m in k['messages']
      let fixable = has_key(m, 'fix') ? '[Fix]' : ''
      let text = printf('[TextLint]%s %s (%s)', fixable, m['message'], m['ruleId'])

      call add(outputs, {
            \ 'filename': file,
            \ 'lnum': m['line'],
            \ 'col': m['column'],
            \ 'vcol': 0,
            \ 'text': text,
            \ 'type': 'E'
            \})
    endfor
  endfor

  return outputs
endfunction

function! s:callback(ch, msg)
  try
    let results = json_decode(a:msg)
    let outputs = s:parse(results)
    if len(outputs) == 0
      " No Errors. Clear quickfix then close window if exists.
      call setqflist([], 'r')
      cclose
      return
    endif

    " Create quickfix via setqflist().
    let mode = g:textlint_clear_quickfix == 1 ? 'r' : 'a'
    call setqflist(outputs, mode)
    if len(outputs) && g:textlint_enable_quickfix == 1
      cwindow
    endif
  catch
    echohl Error | echomsg a:msg | echohl None
  endtry
endfunction

function! s:exit_fix_callback(ch, msg, tmpfile)
  try
    let view = winsaveview()
    let lines = readfile(a:tmpfile)
    silent execute '% delete'
    call setline(1, lines)
    call winrestview(view)
  catch
  endtry
endfunction

function! s:exit_callback(ch, msg)
  " No errors.
  if has_key(g:textlint_callbacks, 'after_run')
    call g:textlint_callbacks['after_run'](a:ch, a:msg)
  endif
endfunction

" Build textlint cmmand {name,value} complete.
function! textlint#complete(lead, cmd, pos)
  let cmd = split(a:cmd)
  let size = len(cmd)
  if size <= 1
    " Command line name completion.
    let args = map(copy(s:textlint_complete), '"-" . v:val . " "')
    return filter(args, 'v:val =~# "^".a:lead')
  endif
  " Command line value completion.
  let name = cmd[1]
  let filter_cmd = printf('v:val =~ "^%s"', a:lead)

  return filter(g:textlint_configs, filter_cmd)
endfunction

" Detect textlint bin and config file.
function! textlint#init(autofix, root_path)
  let textlint = g:textlint_bin == '' ? s:detect_textlint_bin(a:root_path) : g:textlint_bin
  let config = s:build_config(a:root_path, a:autofix)

  let s:textlint['bin'] = textlint
  let s:textlint['config'] = config

  return s:textlint
endfunction

function! s:get_textlint_cmd(args, autofix) abort
  if has_key(g:textlint_callbacks, 'before_run')
    call g:textlint_callbacks['before_run']()
  endif

  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  call s:parse_options(a:args)
  let s:root_path = s:get_root_path(expand('%:p'))
  let s:textlint = textlint#init(a:autofix, s:root_path)
  if s:textlint['bin'] == ''
    return ''
  endif

  return s:build_textlink(s:textlint['bin'], s:textlint['config'])
endfunction

function! s:send(cmd, autofix) abort
  let bufnum = bufnr('%')
  let buflines = getbufline(bufnum, 1, '$')
  if a:autofix == 0
    let s:job = job_start(a:cmd, {
          \ 'callback': {c, m -> s:callback(c, m)},
          \ 'exit_cb': {c, m -> s:exit_callback(c, m)},
          \ 'in_mode': 'nl',
          \ })
    let channel = job_getchannel(s:job)
    if ch_status(channel) ==# 'open'
      let input = join(buflines, "\n") . "\n"
      call ch_sendraw(channel, input)
      call ch_close_in(channel)
    endif
  else
    let t = tempname()
    let tmpfile = printf('%s_textlint_%s', t, expand('%:t'))
    call rename(t, tmpfile)
    call writefile(buflines, tmpfile)
    let cmd = printf(a:cmd, tmpfile)

    let s:job = job_start(cmd, {
          \ 'callback': {c, m -> s:callback(c, m)},
          \ 'exit_cb': {c, m -> s:exit_fix_callback(c, m, tmpfile)},
          \ 'in_io': 'file',
          \ 'in_name': tmpfile,
          \ })
  endif
endfunction

function! textlint#run(...)
  let args = ''
  if len(a:000) > 0
    let args = a:000[0]
  endif
  let cmd = s:get_textlint_cmd(args, 0)
  if cmd == ''
    echohl Error | echomsg 'textlint not found.' | echohl None
    return
  endif
  call s:send(cmd, 0)
endfunction

function! textlint#fix(...) abort
  let args = ''
  if len(a:000) > 0
    let args = a:000[0]
  endif
  let cmd = s:get_textlint_cmd(args, 1)
  if cmd == ''
    echohl Error | echomsg 'textlint not found.' | echohl None
    return
  endif
  let cmd = printf('%s --fix', cmd)
  call s:send(cmd, 1)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
