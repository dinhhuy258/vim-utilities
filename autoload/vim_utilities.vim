let s:cpo_save = &cpo
set cpo&vim

"================================================================================#
"                                 Vim move                                       #
"================================================================================#

" Reference: https://github.com/matze/vim-move

function! vim_utilities#MoveVertically(first, last, distance) abort
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

function! vim_utilities#MoveLineVertically(distance) abort
  let l:old_col    = col('.')
  normal! ^
  let l:old_indent = col('.')

  call vim_utilities#MoveVertically('.', '.', a:distance)

  normal! ^
  let l:new_indent = col('.')
  call cursor(line('.'), max([1, l:old_col - l:old_indent + l:new_indent]))
endfunction

function! vim_utilities#MoveBlockVertically(distance) abort
  call vim_utilities#MoveVertically("'<", "'>", a:distance)
  normal! gv
endfunction

function! vim_utilities#MoveHorizontally(corner_start, corner_end, distance) abort
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

function! vim_utilities#MoveCharHorizontally(distance) abort
  call vim_utilities#MoveHorizontally('.', '.', a:distance)
endfunction

function! vim_utilities#MoveBlockHorizontally(distance) abort
  execute "normal! g`<\<C-v>g`>"
  if vim_utilities#MoveHorizontally("'<", "'>", a:distance)
    execute "normal! g`[\<C-v>g`]"
  endif
endfunction

"================================================================================#
"                             Highlighted yank                                   #
"================================================================================#

" Reference: https://github.com/justinmk/vim-highlightedyank

function! vim_utilities#HighlightedYank(regtype) abort
  if v:event.operator !=# 'y' || v:event.regtype ==# ''
    return
  endif

  let bnr = bufnr('%')
  let ns = nvim_create_namespace('')
  call nvim_buf_clear_namespace(bnr, ns, 0, -1)

  let [_, lin1, col1, off1] = getpos("'[")
  let [lin1, col1] = [lin1 - 1, col1 - 1]
  let [_, lin2, col2, off2] = getpos("']")
  let [lin2, col2] = [lin2 - 1, col2]
  for l in range(lin1, lin1 + (lin2 - lin1))
    let is_first = (l == lin1)
    let is_last = (l == lin2)
    let c1 = is_first ? (col1 + off1) : 0
    let c2 = is_last ? (col2 + off2) : -1
    call nvim_buf_add_highlight(bnr, ns, 'Yank', l, c1, c2)
  endfor

  call timer_start(1000, {-> nvim_buf_clear_namespace(bnr, ns, 0, -1)})
endfunction

"================================================================================#
"                                Cursor word                                     #
"================================================================================#

" Reference: https://github.com/itchyny/vim-cursorword

let s:timer = 0
let s:delay = 50
let s:alphabets = '^[\x00-\x7f\xb5\xc0-\xd6\xd8-\xf6\xf8-\u01bf\u01c4-\u02af\u0370-\u0373\u0376\u0377\u0386-\u0481\u048a-\u052f]\+$'

function! vim_utilities#CursorWordHighlight() abort
  highlight CursorWord0 term=underline cterm=underline gui=underline
  redir => out
    silent! highlight CursorLine
  redir END
  let highlight = 'highlight CursorWord1 term=underline cterm=underline gui=underline'
  execute highlight matchstr(out, 'ctermbg=#\?\w\+') matchstr(out, 'guibg=#\?\w\+')
endfunction

function! vim_utilities#MatchAdd(...) abort
  let l:vim_started =  !has('vim_starting')
  if !l:vim_started && !get(w:, 'cursorword_match') | return | endif
  let l:i = (a:0 ? a:1 : mode() ==# 'i' || mode() ==# 'R') && col('.') > 1
  let l:line = getline('.')
  let l:linenr = line('.')
  let l:word = matchstr(l:line[:(col('.') - l:i - 1)], '\k*$') . matchstr(l:line[(col('.') - l:i - 1):], '^\k*')[1:]
  if get(w:, 'cursorword_state', []) ==# [ l:linenr, l:word, l:vim_started ] | return | endif
  let w:cursorword_state = [ l:linenr, l:word, l:vim_started ]
  if exists('w:last_cursor_word') && w:last_cursor_word ==# l:word
    return
  endif
  let w:last_cursor_word = l:word
  if get(w:, 'cursorword_match')
    silent! call matchdelete(w:cursorword_id0)
    silent! call matchdelete(w:cursorword_id1)
  endif
  let w:cursorword_match = 0
  if !l:vim_started || l:word ==# '' || len(l:word) !=# strchars(l:word) && l:word !~# s:alphabets || len(l:word) > 1000 | return | endif
  let l:pattern = '\<' . escape(l:word, '~"\.^$[]*') . '\>'
  let w:cursorword_id0 = matchadd('CursorWord0', l:pattern, -100)
  let w:cursorword_id1 = matchadd('CursorWord' . &l:cursorline, '\%' . l:linenr . 'l' . l:pattern, -100)
  let w:cursorword_match = 1
endfunction

function! vim_utilities#CursorMoved() abort
  if get(w:, 'cursorword_match')
    silent! call matchdelete(w:cursorword_id0)
    silent! call matchdelete(w:cursorword_id1)
    let w:cursorword_match = 0
    let w:cursorword_state = []
  endif
  call timer_stop(s:timer)
  let s:timer = timer_start(s:delay, 'vim_utilities#TimerCallback')
endfunction

function! vim_utilities#TimerCallback(...) abort
  call vim_utilities#MatchAdd()
endfunction

"================================================================================#
"                                    End                                         #
"================================================================================#

let &cpo = s:cpo_save
unlet s:cpo_save

