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

  * Discovers `.gitignore` files in your repository automatically, without
    using `**/.gitignore` searching.
  * Buffer-local `wildignore` values - so you can switch between buffers
    without worrying about global state.
  * Handles negated ignores!
    * This is done by using `git ls-files -o -i --exclude-standard`, so
      whatever git claims is an ignored file, is ignored. This might be a
      slight performance hit if your repository has lots of ignored files (e.g.
      `.pyc` files, or whatever). I don't know this for sure, though.
    * Enable by adding the following to your `.vimrc` file:

                let g:gitwildignore_use_ls_files = 1


## TODO

  * Add support for ignore negations (leading `!` characters) when not using
    `git ls-files`
  * Investigate whether buffer-local `wildignore` is really necessary, given
    that the `.gitignore` entries have the directory path prepended to them.
  * Make sure this works right when exploring in netrw.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/mikewadsten/vim-gitwildignore/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
