vim-textlint
============

Currently WIP.

Wrapper for [textlint](https://textlint.github.io/).

Motivations
-----------
I want to load `textlint` config file dynamically.

[Syntastic](https://github.com/scrooloose/syntastic) can use `textlint` but not support config file.

[watchdocs.vim](https://github.com/osyo-manga/vim-watchdogs) also has `textlint` settings but not supporting config file.


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

Integration
------------

`vim-textlint` can integrate with [watchdocs.vim](https://github.com/osyo-manga/vim-watchdogs).

Configure followings to your `.vimrc`.
```viml
" Enable vim-textlint config
let g:quickrun_config['markdown/watchdogs_checker'] = {
  \ 'type': 'watchdogs_checker/textlint',
  \ 'hook/watchdogs_quickrun_running_textlint/enable': 1,
  \ }
```

Run `watchdocs.vim`.

```viml
:WatchdogsRun
```
