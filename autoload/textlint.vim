" File: textlint.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version: 1.0.0
" WebPage: http://github.com/heavenshell/vim-textlint.
" Description: Vim plugin for TextLint
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

let g:textlint_configs = get(g:, 'textlint_configs', [])
let g:textlint_enable_quickfix = get(g:, 'textlint_enable_quickfix', 0)
let g:textlint_clear_quickfix = get(g:, 'textlint_clear_quickfix', 1)
let g:textlint_callbacks = get(g:, 'textlint_callbacks', {})

" TODO Not implemented. Support --rules.
if !exists('g:textlint_rules')
  let g:textlint_rues = []
endif

let s:textlint_config = ''
let s:textlint_complete = ['c']

let s:textlint = {}

function! s:detect_textlint_bin(srcpath)
  let textlint = ''
  if executable('textlint') == 0
    let root_path = finddir('node_modules', a:srcpath . ';')
    if root_path == ''
      return ''
    endif
    let textlint = root_path . '/.bin/textlint'
  else
    let textlint = exepath('textlint')
  endif

  return textlint
endfunction

function! s:build_config(srcpath)
  let root_path = fnamemodify(finddir('node_modules', a:srcpath . ';'), ':p')
  if s:textlint_config == '' && len(g:textlint_configs) > 0
    let s:textlint_config = g:textlint_configs[0]
  endif

  let file = expand('%:p')
  if s:textlint_config == ''
    let config_path = printf(' --stdin --stdin-filename %s --format json ', file)
  else
    let config_path = printf(' --config=%s/%s --stdin --stdin-filename %s --format json ', root_path, s:textlint_config, file)
  endif

  return config_path
endfunction

" Build textlint bin path.
function! s:build_textlink(binpath, configpath, target)
  let cmd = a:binpath . a:configpath . '%'
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
      call add(outputs, {
            \ 'filename': file,
            \ 'lnum': m['line'],
            \ 'col': m['column'],
            \ 'vcol': 0,
            \ 'text': printf('[TextLint] %s (%s)', m['message'], m['ruleId']),
            \ 'type': 'E'
            \})
    endfor
  endfor

  return outputs
endfunction

function! s:callback(ch, msg)
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
endfunction

function! s:exit_callback(ch, msg)
  " No errors.
  if has_key(g:textlint_callbacks, 'after_run')
    call g:textlint_callbacks['after_run'](a:ch, a:msg)
  endif
endfunction

" Build textlint cmmand {name,value} complete.
function! textlint#complete(lead, cmd, pos) abort
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
function! textlint#init()
  let textlint = s:detect_textlint_bin(expand('%:p'))
  let config = s:build_config(expand('%:p'))

  let s:textlint['bin'] = textlint
  let s:textlint['config'] = config

  return s:textlint
endfunction

function! textlint#run(...)
  if has_key(g:textlint_callbacks, 'before_run')
    call g:textlint_callbacks['before_run']()
  endif

  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let args = ''
  if len(a:000) > 0
    let args = a:000[0]
  endif

  call s:parse_options(args)

  if s:textlint == {}
    call textlint#init()
  endif
  let textlint = s:textlint['bin']
  if textlint == ''
    return
  endif
  let config = s:textlint['config']

  let file = expand('%:p')
  let cmd = s:build_textlink(textlint, config, expand('%:p'))
  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:callback(c, m)},
        \ 'exit_cb': {c, m -> s:exit_callback(c, m)},
        \ 'in_io': 'buffer',
        \ 'in_name': file,
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
