vim-textlint
============

Currently WIP.

Wrapper for [textlint](https://textlint.github.io/).

Configure
---------

Add `textlint` config file name to your `.vimrc`.
```viml
" textlint.vim {{{
let g:textlint_configs = [
  \ '@azu/textlint-config-readme'
  \ '@example/textlint-config-example',
  \ ]
" }}}
```

Usage:
------

Use `g:textlint_configs`'s first value.
```viml
:Textlint
```

Select config file.
```viml
:Textlint -c @example/textlint-config-example
```

Run.
```viml
:silent make|redraw|copen
```
