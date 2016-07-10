" File: textlint.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version: 0.1.0
" WebPage: http://github.com/heavenshell/vim-textlint.
" Description: Vim plugin for TextLint
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -buffer -complete=customlist,textlint#complete Textlint call textlint#setup(<q-args>, <count>, <line1>, <line2>)

let &cpo = s:save_cpo
unlet s:save_cpo

