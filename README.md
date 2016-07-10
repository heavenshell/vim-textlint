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
  \ '@azu/textlint-config-readme',
  \ '@example/textlint-config-example',
  \ ]
" }}}
```

Usage
-----

```viml
:Textlint
```
If you did not set any args, `vim-textlint` would use `g:textlint_configs`'s first value.

```viml
:Textlint -c @example/textlint-config-example
```
You can select `textlint` config file via command line.

```viml
:silent make|redraw|copen
```
Execute `textlint` via `:make`.

Helpful plugins
---------------

[QuickFixstatus](https://github.com/dannyob/quickfixstatus) shows error message at the bottom of the screen.

[Hier](https://github.com/cohama/vim-hier) will highlight `quickfix` errors and location list entries in buffer.
