vim-gitwildignore
=================

Install and every file/directory in your project's ``.gitignore`` files will be
appended to your wildignore. Useful when accompanied with the
[ctrlp.vim](https://github.com/kien/ctrlp.vim) plugin.

## Installation
Use [vundle](https://github.com/gmarik/vundle), and add the following your ``vimrc`` file:
```vim
Bundle 'mikewadsten/vim-gitwildignore'
```

## Added features (versus [zdwolfe/vim-gitwildignore](https://github.com/zdwolfe/vim-gitwildignore))

  * Recurse down the directory tree to discover `.gitignore` files (rather than
    searching `**/.gitignore`)
    * I now realize that this means `**/.gitignore` is not being searched...
      I should fix that.

  * Buffer-local `wildignore` values - so you can switch between buffers
    without worrying about global state.

## TODO

  * Add back in the search for `**/.gitignore` since that's actually useful.
  * Investigate whether buffer-local `wildignore` is really necessary, given
    that the `.gitignore` entries have the directory path prepended to them.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/mikewadsten/vim-gitwildignore/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
