" File: textlint.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version: 0.2.0
" WebPage: http://github.com/heavenshell/vim-textlint.
" Description: Vim plugin for TextLint
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim
if exists('g:textlint_loaded')
  finish
endif
let g:textlint_loaded = 1

if !exists('g:textlint_configs')
  let g:textlint_configs = []
endif

" TODO Not implemented. Support --rules.
if !exists('g:textlint_rules')
  let g:textlint_rues = []
endif

let s:textlint_config = ''

let s:textlint_complete = ['c']

let s:textlint = {}

function! s:detect_textlint_bin(srcpath) abort
  if executable('textlint') == 0
    let root_path = finddir('node_modules', a:srcpath . ';')
    let textlint = root_path . '/.bin/textlint'
  endif

  return textlint
endfunction

function! s:build_config(srcpath) abort
  let root_path = finddir('node_modules', a:srcpath . ';')
  if s:textlint_config == '' && len(g:textlint_configs) > 0
    let s:textlint_config = g:textlint_configs[0]
  endif
  if s:textlint_config == ''
    let config_path = printf(' -f compact ')
  else
    let config_path = printf(' --config=%s/%s -f compact ', root_path, s:textlint_config)
  endif
  return config_path
endfunction

" Build textlint bin path.
function! s:build_textlink(binpath, configpath, target) abort
  let cmd = a:binpath . a:configpath . '%'
  return cmd
endfunction

function! s:parse_options(args) abort
  if a:args =~ '-c\s'
    let args = split(a:args, '-c\s')
    if len(args) > 0
      let s:textlint_config = matchstr(args[0],'^\s*\zs.\{-}\ze\s*$')
    endif
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
function! textlint#init() abort
  let textlint = s:detect_textlint_bin(expand('%:p'))
  let config = s:build_config(expand('%:p'))

  let s:textlint['bin'] = textlint
  let s:textlint['config'] = config

  return s:textlint
endfunction

" Setup textlint settings.
function! textlint#setup(...)
  call s:parse_options(a:000[0])
  let ret = textlint#init()
  let textlint = ret['bin']
  let config = ret['config']

  let textlink = s:build_textlink(textlint, config, expand('%:p'))
  let cmd = substitute(textlink, '\s', '\\ ', 'g')
  "let &makeprg did not work properly.
  execute 'set makeprg=' . cmd

  " Errorformat for `textlint -f compact`.
  let fmt =
    \ '%E%f: line %l\, col %c\, Error - %m,' .
    \ '%W%f: line %l\, col %c\, Warning - %m,' .
    \ '%-G%.%#'

  let &errorformat = fmt
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
