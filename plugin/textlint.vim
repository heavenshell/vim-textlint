" File: textlint.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version: 1.0.0
" WebPage: http://github.com/heavenshell/vim-textlint.
" Description: Vim plugin for TextLint
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

if get(b:, 'loaded_textlint')
  finish
endif

" version check
if !has('channel') || !has('job')
  echoerr '+channel and +job are required for textlint.vim'
  finish
endif

command! -nargs=* -buffer -complete=customlist,textlint#complete Textlint call textlint#run(<q-args>, <count>, <line1>, <line2>)

let b:loaded_textlint = 1

let &cpo = s:save_cpo
unlet s:save_cpo
