" File: textlint.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version: 1.2.0
" WebPage: http://github.com/heavenshell/vim-textlint.
" Description: Vim plugin for TextLint
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

if expand('%:p') ==# expand('<sfile>:p')
  unlet! b:loaded_textlint
endif

if get(b:, 'loaded_textlint')
  finish
endif

" version check
if !has('channel') || !has('job')
  echoerr '+channel and +job are required for textlint.vim'
  finish
endif

command! -nargs=* -complete=customlist,textlint#complete Textlint call textlint#run(<q-args>, <count>, <line1>, <line2>)
command! -nargs=* -complete=customlist,textlint#complete TextlintFix call textlint#fix(<q-args>, <count>, <line1>, <line2>)

noremap <silent> <buffer> <Plug>(Textlint)  :Textlint <CR>
noremap <silent> <buffer> <Plug>(TextlintFix)  :TextlintFix <CR>

let b:loaded_textlint = 1

let &cpo = s:save_cpo
unlet s:save_cpo
