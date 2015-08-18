" gitwildignore - Vundle plugin for appending files in .gitignore to wildignore
" Original Author: Zach Wolfe <zdwolfe.github.io>
" Inspired by Adam Bellaire's gitignore script
"
" Maintainer: Mike Wadsten
" Version 0.0.3

if exists('g:loaded_gitwildignore')
  finish
endif

let g:loaded_gitwildignore = 1

" set to 0 to read .gitignore files rather than using
" `git ls-files -oi --exclude-standard` to get ignored files.
if !exists('g:gitwildignore_use_ls_files')
  let g:gitwildignore_use_ls_files = 1
endif

" Return essentially '<path>/..'
function! s:updir(path)
  return fnamemodify(a:path, ":h")
endfunction

function! gitwildignore#find_git_root(path)
  if a:path =~ ''
    let l:filepath = expand('%:p:h')
  else
    let l:filepath = a:path
  endif

  " We already found the git root, so just return it.
  if exists('b:git_root')
    return b:git_root
  endif

  " Use rev-parse to give us the root directory... this fixes issues with being
  " inside submodules.
  " (show-cdup gives us the relative path to the root. show-toplevel would give
  " us the absolute path, which ends up being problematic when using symlinks)

  " Hold your horses, me. First, are we even in a working directory?
  let l:inworkdir = system('git rev-parse --is-inside-work-tree')
  if l:inworkdir =~ '^fatal:'
    " Not inside a Git repository at all. Abort abort abort
    " (Typically happens when running `git commit` and its ilk.)
    return ''
  endif

  let l:revparseoutput = system('git rev-parse --show-cdup')
  if l:revparseoutput =~ '^fatal:'
    " What? I don't even
    echoe "Failed to figure out where the git root was:" . l:revparseoutput
    return ''
  endif

  let l:split_output = split(l:revparseoutput, '\n')
  if len(l:split_output)
    " Get first line of output
    " Remove the trailing slash
    let b:git_root = substitute(l:split_output[0], '/$', '', '')
  else
    " Output was empty -- we're sitting at the root directory.
    let b:git_root = '.'
  endif

  return b:git_root
endfunction

function! gitwildignore#get_file_patterns(ignorefile)
  let l:gitignore = fnamemodify(a:ignorefile, ':p')
  let l:ignorepath = fnamemodify(l:gitignore, ':h')

  let l:ignore_patterns = []
  let l:include_patterns = []

  if filereadable(l:gitignore)
    " Parse .gitignore file according to Git docs
    " http://git-scm.com/docs/gitignore#_pattern_format
    for line in readfile(l:gitignore)
      let l:ignore_pattern = ''
      let l:include_pattern = ''
      if line =~ '^#' || line == ''
        " Skip comments and empty lines
        continue
      elseif line =~ '^!'
        " Lines starting with ! negates the given search pattern. Any matching
        " file excluded by a previous (earlier, higher-up) pattern will be
        " included again. If a parent directory is excluded, this has no
        " effect (the file is not re-included).
        let l:include_pattern = line[1:]
      elseif line =~ '/$'
        " Explicit directory ignore.
        let l:directory = substitute(line, '/$', '', '')
        if isdirectory(l:ignorepath . '/' . l:directory)
          " Ignore the directory and anything inside it
          let l:ignore_pattern = l:directory . '/**'
        else
          " It's not a directory, so just skip it
          continue
        endif
      else
        let l:ignore_pattern = line
      endif

      if strlen(l:ignore_pattern)
        " We got an ignore pattern out of the line
        let l:ignore_patterns += [ l:ignorepath . '/' . l:ignore_pattern ]
      elseif strlen(l:include_pattern)
        " We got an un-include pattern out of the line
        let l:include_patterns += [ l:ignorepath . '/' . l:include_pattern ]
      endif
    endfor
  endif

  return {'ignore': l:ignore_patterns, 'include': l:include_patterns}
endfunction

function! gitwildignore#discover_gitignore_files(root)
  " a:root is the root of the Git repository.
  " This will error out if you pass in a root path that's outside the
  " repository, but that should only happen if you call this manually...

  let l:findcmd = 'git ls-files "' . a:root . '"'
  let l:findcmd .= "| grep '\.gitignore$'"
  let l:findoutput = system(l:findcmd)
  let l:files = split(l:findoutput, '\n')

  if l:findoutput =~ "^fatal:"
    " Suppress errors from being inside the .git/ directory
    if !(l:findoutput =~ "^fatal: This operation must be run in a work tree")
      echoe "gitwildignore couldn't discover .gitignore files:"
      echoe l:findoutput
    endif
    let l:files = []
  endif

  return l:files
endfunction

function! gitwildignore#get_ignored_by_lsfiles(root)
  " --directory means that, if an entire directory is ignored rather than just
  "  some files inside it, then return just the directory name/path.
  " -C tells git to pretend the current work tree is that argument
  let l:cmd = "git -C __root__ ls-files -oi --exclude-standard --directory"
  let l:cmd = substitute(l:cmd, '__root__', a:root, 'g')

  let l:output = system(l:cmd)
  let l:ignored = split(l:output, '\n')

  if l:output =~ "^fatal:"
    " Suppress errors from being inside the .git/ directory
    if !(l:output =~ "^fatal: This operation must be run in a work tree")
      echoe "gitwildignore couldn't get ignored files:"
      echoe l:output
    endif
    let l:ignored = []
  endif

  " To get Vim to ignore directories, we need to remove the trailing slash.
  let l:ignored_files = []
  for file in l:ignored
    if file =~ '/$'
      " Ignore the directory and anything inside it, by adding *
      let l:ignored_files += [ file . '*' ]
    endif

    let l:ignored_files += [ file ]
  endfor

  return l:ignored_files
endfunction

function! gitwildignore#get_all_ignores(path)
  let l:gitignore_files = []
  let l:git_root = gitwildignore#find_git_root(a:path)
  let l:curpath = fnamemodify(a:path, ':p:h')

  let l:ignore_patterns = {'ignore': [], 'include': []}

  if !strlen(l:git_root)
    " No Git root was found. Don't try to do any processing.
    return l:ignore_patterns
  endif

  if g:gitwildignore_use_ls_files
    let l:root = fnameescape(l:git_root)
    let l:lsfiles = gitwildignore#get_ignored_by_lsfiles(l:root)
    for file in l:lsfiles
      " apparently git ls-files gives the file locations relative to the cwd
      " when it is called.
      let l:path = simplify(l:root . '/' . file)
      " Strip leading './' because that's just useless
      if l:path =~ '^\./'
        let l:path = strpart(l:path, 2)
      endif
      let l:ignore_patterns.ignore += [ l:path ]
    endfor
  else
    let l:gitignore_files = gitwildignore#discover_gitignore_files(l:git_root)

    " Collect ignore patterns from each ignorefile
    for f in l:gitignore_files
      let l:patterns = gitwildignore#get_file_patterns(f)
      let l:ignore_patterns.ignore += l:patterns.ignore
      let l:ignore_patterns.include += l:patterns.include
    endfor
  endif

  return l:ignore_patterns
endfunction

" Ignore-patterns cache, keyed by git root. Save a minor amount of processing,
" but also useful for debugging, maybe.

if !exists('g:gitwildignore_patterns')
  let g:gitwildignore_patterns = {}
endif

if !has_key(g:gitwildignore_patterns, '/')
  let g:gitwildignore_patterns['/'] = ['*.pyc', '*.sw[op]']
endif

function! gitwildignore#init(path)
  " TODO: Add setting for skipped filetypes.
  if &filetype == "gitcommit"
    return
  endif

  " Based on vim-fugitive fugitive#detect function
  if exists('b:git_root') && (b:git_root ==# '' || b:git_root =~# '/$')
    unlet b:git_root
  endif

  if !exists('b:git_root')
    let dir = gitwildignore#find_git_root(a:path)
    if dir !=# ''
      let b:git_root = dir
    endif
  endif

  if !exists('b:git_root')
    let l:wildignorelist = g:gitwildignore_patterns['/']
  else
    " Look up cached ignore values.
    if has_key(g:gitwildignore_patterns, b:git_root)
      let l:ignored = g:gitwildignore_patterns[b:git_root]
    else
      let l:ignored = []
    endif

    " Detect ignored files now, merge them in with l:ignored
    let l:detected = gitwildignore#get_all_ignores(a:path)

    for ignore in l:detected.ignore
      " Add each ignore which is not already in the list.
      if !count(l:ignored, ignore)
        let l:ignored += [ignore]
      endif
    endfor

    let g:gitwildignore_patterns[b:git_root] = l:ignored

    let l:wildignorelist = g:gitwildignore_patterns['/'] + l:ignored
  endif

  " fnameescape ALL the files!
  let l:wildignorelist_escaped = []
  for fname in l:wildignorelist
    " Need two slashes to really escape commas, so that means we need to use
    " EIGHT in the substitution... *sigh*
    let escaped = substitute(fnameescape(fname), ",", "\\\\\\\\,", "g")
    let l:wildignorelist_escaped += [ escaped ]
  endfor

  let l:wildignorelist = l:wildignorelist_escaped
  let l:wildignore = join(l:wildignorelist, ',')

  let b:wildignorelist = l:wildignorelist
  execute "set wildignore=" . l:wildignore
endfunction

function! gitwildignore#leave()
  if exists('b:wildignorelist')
    unlet b:wildignorelist
    " Restore wildignore to the "global" ignore pattern.
    execute "set wildignore=" . join(g:gitwildignore_patterns['/'], ',')
  endif
endfunction

augroup gitwildignore
  autocmd!
  " Set wildignore when you go into a buffer.
  autocmd BufEnter * call gitwildignore#init(expand('<amatch>:p:h'))
  " Cleanup when leaving a buffer.
  autocmd BufLeave * call gitwildignore#leave()
augroup END
