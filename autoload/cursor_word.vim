let s:cpo_save = &cpo
set cpo&vim

" Reference: https://github.com/itchyny/vim-cursorword

let s:timer = 0
let s:delay = 50
let s:alphabets = '^[\x00-\x7f\xb5\xc0-\xd6\xd8-\xf6\xf8-\u01bf\u01c4-\u02af\u0370-\u0373\u0376\u0377\u0386-\u0481\u048a-\u052f]\+$'

function! s:GetCurrentWord() abort
  let l:i = mode() ==# 'R' && col('.') > 1
  let l:line = getline('.')

  return matchstr(l:line[:(col('.') - l:i - 1)], '\k*$') . matchstr(l:line[(col('.') - l:i - 1):], '^\k*')[1:]
endfunction

function! cursor_word#CursorWordHighlight() abort
  highlight CursorWord0 term=underline cterm=underline gui=underline
  redir => out
    silent! highlight CursorLine
  redir END
  let highlight = 'highlight CursorWord1 term=underline cterm=underline gui=underline'
  execute highlight matchstr(out, 'ctermbg=#\?\w\+') matchstr(out, 'guibg=#\?\w\+')
endfunction

function! cursor_word#MatchAdd() abort
  if &buftype != "" && &buftype != "acwrite"
    return
  endif

  let l:vim_started =  !has('vim_starting')
  if !l:vim_started && !get(w:, 'cursor_word_match') | return | endif
  let l:i = mode() ==# 'R' && col('.') > 1
  let l:linenr = line('.')
  let l:word = s:GetCurrentWord()
  if get(w:, 'cursor_word_state', []) ==# [ l:linenr, l:word, l:vim_started ] | return | endif
  let w:cursor_word_state = [ l:linenr, l:word, l:vim_started ]
  if get(w:, 'cursor_word_match')
    silent! call matchdelete(w:cursor_word_id0)
    silent! call matchdelete(w:cursor_word_id1)
  endif
  let w:cursor_word_match = 0
  if !l:vim_started || l:word ==# '' || len(l:word) !=# strchars(l:word) && l:word !~# s:alphabets || len(l:word) > 1000 | return | endif
  let l:escape_word = escape(l:word, '~"\.^$[]*')
  let l:escape_word_len = strlen(l:escape_word)
  if  l:escape_word_len > 1 && l:escape_word[l:escape_word_len - 1] == '-'
    let l:pattern = '\(\<' . l:escape_word . '\>\|\<' . l:escape_word[0: l:escape_word_len - 2] . '\>\)'
  else
    let l:pattern = '\(\<' . l:escape_word . '\>\|\<' . l:escape_word . '->\)'
  endif
  let w:cursor_word_id0 = matchadd('CursorWord0', l:pattern, -100)
  let w:cursor_word_id1 = matchadd('CursorWord' . &l:cursorline, '\%' . l:linenr . 'l' . l:pattern, -100)
  let w:cursor_word_match = 1
endfunction

function! cursor_word#MatchDelete()
  silent! call matchdelete(w:cursor_word_id0)
  silent! call matchdelete(w:cursor_word_id1)
  let w:cursor_word_match = 0
  let w:cursor_word_state = []
endfunction

function! cursor_word#CursorMoved() abort
  if get(w:, 'cursor_word_match')
    let l:word = s:GetCurrentWord()
    if w:cursor_word_state[1] ==# l:word
      return
    endif
    call cursor_word#MatchDelete()
  endif

  call timer_stop(s:timer)
  let s:timer = timer_start(s:delay, 'cursor_word#TimerCallback')
endfunction

function! cursor_word#TimerCallback(...) abort
  call cursor_word#MatchAdd()
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

