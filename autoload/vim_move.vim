let s:cpo_save = &cpo
set cpo&vim

" Reference: https://github.com/matze/vim-move

function! vim_move#MoveVertically(first, last, distance) abort
  if !&modifiable || a:distance == 0
    return
  endif

  let l:first = line(a:first)
  let l:last  = line(a:last)

  let l:old_pos = getcurpos()
  if a:distance < 0
    call cursor(l:first, 1)
    execute 'normal!' (-a:distance).'k'
    let l:after = line('.') - 1
  else
    call cursor(l:last, 1)
    execute 'normal!' a:distance.'j'
    let l:after = (foldclosedend('.') == -1 ? line('.') : foldclosedend('.'))
  endif

  call setpos('.', l:old_pos)

  execute l:first ',' l:last 'move' l:after

  " Auto indent
  let l:first = line("'[")
  let l:last  = line("']")

  call cursor(l:first, 1)
  normal! ^
  let l:old_indent = virtcol('.')
  normal! ==
  let l:new_indent = virtcol('.')

  if l:first < l:last && l:old_indent != l:new_indent
    let l:op = (l:old_indent < l:new_indent
      \  ? repeat('>', l:new_indent - l:old_indent)
      \  : repeat('<', l:old_indent - l:new_indent))
    let l:old_sw = &shiftwidth
    let &shiftwidth = 1
    execute l:first+1 ',' l:last l:op
    let &shiftwidth = l:old_sw
  endif

  call cursor(l:first, 1)
  normal! 0m[
  call cursor(l:last, 1)
  normal! $m]
endfunction

function! vim_move#MoveLineVertically(distance) abort
  let l:old_col    = col('.')
  normal! ^
  let l:old_indent = col('.')

  call vim_move#MoveVertically('.', '.', a:distance)

  normal! ^
  let l:new_indent = col('.')
  call cursor(line('.'), max([1, l:old_col - l:old_indent + l:new_indent]))
endfunction

function! vim_move#MoveBlockVertically(distance) abort
  call vim_move#MoveVertically("'<", "'>", a:distance)
  normal! gv
endfunction

function! vim_move#MoveHorizontally(corner_start, corner_end, distance) abort
  if !&modifiable || a:distance == 0
    return 0
  endif

  let l:cols = [col(a:corner_start), col(a:corner_end)]
  let l:first = min(l:cols)
  let l:last  = max(l:cols)
  let l:width = l:last - l:first + 1

  let l:before = max([1, l:first + a:distance])
  if a:distance > 0
    let l:lines = getline(a:corner_start, a:corner_end)
    let l:shortest = min(map(l:lines, 'strwidth(v:val)'))
    if l:last < l:shortest
      let l:before = min([l:before, l:shortest - l:width + 1])
    else
      let l:before = l:first
    endif
  endif

  if l:first == l:before
    return 0
  endif

  let l:old_default_register = @"
  normal! x

  let l:old_virtualedit = &virtualedit
  if l:before >= col('$')
    let &virtualedit = 'all'
  else
    let &virtualedit = ''
  endif

  call cursor(line('.'), l:before)
  normal! P

  let &virtualedit = l:old_virtualedit
  let @" = l:old_default_register

  return 1
endfunction

function! vim_move#MoveCharHorizontally(distance) abort
  call vim_move#MoveHorizontally('.', '.', a:distance)
endfunction

function! vim_move#MoveBlockHorizontally(distance) abort
  execute "normal! g`<\<C-v>g`>"
  if vim_move#MoveHorizontally("'<", "'>", a:distance)
    execute "normal! g`[\<C-v>g`]"
  endif
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
