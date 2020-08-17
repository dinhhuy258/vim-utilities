if exists('s:vim_utilities_loaded')
   finish
endif
let s:vim_utilities_loaded = 1

let s:cpo_save = &cpo
set cpo&vim

"================================================================================#
"                       Remove trailing whitespaces                              #
"================================================================================#

command! FixWhitespace :%s/\s\+$//e

"================================================================================#
"                          Convert tab to space                                  s#
"================================================================================#

command! ConvertTabToSpace :%s/\t/    /g

"================================================================================#
"                    Boost performance for large buffer                          #
"================================================================================#

augroup vim_utilities_boost_performance_for_large_buffer
  autocmd!
  autocmd BufReadPost,FileReadPost * call s:ImprovePerformanceIfLinesOverLimit(800)
augroup END

function! s:ImprovePerformanceIfLinesOverLimit(limit) abort
  if line('$') >= a:limit
    call s:BoostPerformanceForCurrentBuffer()
    echomsg "Boosted Performance. If the problem still persitst, try disable syntax highlighting completely with :syntax off. That would literally solve the root of the problem"
  endif
endfunction

function! s:BoostPerformanceForCurrentBuffer() abort
  setlocal regexpengine=1
  setlocal norelativenumber
  setlocal nonumber
  setlocal nolazyredraw " improve typing issue
  setlocal synmaxcol=200
  setlocal foldmethod=indent " with value is syntax would cause performance
  setlocal maxmempattern=1000 " default value
endfunction

"================================================================================#
"                                 Profiling                                      #
"================================================================================#

command! StartProfiling profile start ~/.profile.log | profile func * | profile file * | echo 'Profiling started'

"================================================================================#
"                              Highlight search                                  #
"================================================================================#

" Reference: https://github.com/romainl/vim-cool

augroup vim_utilities_highlight_search
  autocmd!
  " Trigger when hlsearch is toggled
  autocmd vim_utilities_highlight_search OptionSet hlsearch call <SID>HighlightSearchToggle(v:option_old, v:option_new)
augroup END

function! s:StartHighlightSearch() abort
  silent! if v:hlsearch && !search('\%#\zs'.@/,'cnW')
    call <SID>StopHighlightSearch()
  endif
endfunction

function! s:StopHighlightSearch() abort
  if ! v:hlsearch || mode() isnot 'n'
    return
  endif

  silent call feedkeys("\<Plug>(StopHighlightSearch)", 'm')
endfunction

function! s:HighlightSearchToggle(old, new) abort
  if a:old == 0 && a:new == 1
    " nohls -> hls
    noremap <silent> <Plug>(StopHighlightSearch) :<C-U>nohlsearch<CR>
    noremap! <expr> <Plug>(StopHighlightSearch) execute('nohlsearch')[-1]

    autocmd vim_utilities_highlight_search CursorMoved * call <SID>StartHighlightSearch()
    autocmd vim_utilities_highlight_search InsertEnter * call <SID>StopHighlightSearch()
  elseif a:old == 1 && a:new == 0
    " hls -> nohls
    nunmap <Plug>(StopHighlightSearch)
    unmap! <expr> <Plug>(StopHighlightSearch)

    autocmd! vim_utilities_highlight_search CursorMoved
    autocmd! vim_utilities_highlight_search InsertEnter
  endif
endfunction

call <SID>HighlightSearchToggle(0, &hlsearch)

"================================================================================#
"                              Delete without saving                             #
"================================================================================#

" Reference: https://github.com/svermeulen/vim-cutlass

function! s:OverrideSelectBindings() abort
  let i = 33

  " Add a map for every printable character to copy to black hole register
  while i <= 126
    if i !=# 124
      let char = nr2char(i)
      if i ==# 92
        let char = '\\'
      endif
      exec 'snoremap '. char .' <c-o>"_c'. char
    endif

  let i = i + 1
  endwhile

  snoremap <bs> <c-o>"_c
  snoremap <space> <c-o>"_c<space>
  snoremap \| <c-o>"_c|
endfunction

function! s:HasMapping(mapping, mode) abort
  return maparg(a:mapping, a:mode) != ''
endfunction

function! s:AddWeakMapping(left, right, modes, ...) abort
  let recursive = a:0 > 0 ? a:1 : 0

  for mode in split(a:modes, '\zs')
    if !s:HasMapping(a:left, mode)
      exec mode . (recursive ? "map" : "noremap") . " <silent> " . a:left . " " . a:right
    endif
  endfor
endfunction

function! s:OverrideDeleteAndChangeBindings() abort
  " Keep the x key in visual mode as usual
  let bindings =
  \ [
  \   ['c', '"_c', 'nx'],
  \   ['cc', '"_S', 'n'],
  \   ['C', '"_C', 'nx'],
  \   ['s', '"_s', 'nx'],
  \   ['S', '"_S', 'nx'],
  \   ['d', '"_d', 'nx'],
  \   ['dd', '"_dd', 'n'],
  \   ['D', '"_D', 'nx'],
  \   ['x', '"_x', 'n'],
  \   ['X', '"_X', 'nx'],
  \ ]

  for binding in bindings
    call call("s:AddWeakMapping", binding)
  endfor
endfunction

function! RedirectDefaultsToBlackHole() abort
  call s:OverrideDeleteAndChangeBindings()
  call s:OverrideSelectBindings()
endfunction

call RedirectDefaultsToBlackHole()

"================================================================================#
"                                 Vim move                                       #
"================================================================================#

function s:GetHalfPageSize() abort
  return winheight('.') / 2
endfunction

vnoremap <silent> <Plug>MoveBlockHalfPageDown :<C-u> silent call vim_move#MoveBlockVertically(v:count1 * <SID>GetHalfPageSize())<CR>
vnoremap <silent> <Plug>MoveBlockHalfPageUp :<C-u> silent call vim_move#MoveBlockVertically(-v:count1 * <SID>GetHalfPageSize())<CR>
vnoremap <silent> <Plug>MoveBlockDown :<C-u> silent call vim_move#MoveBlockVertically(v:count1)<CR>
vnoremap <silent> <Plug>MoveBlockUp :<C-u> silent call vim_move#MoveBlockVertically(-v:count1)<CR>
vnoremap <silent> <Plug>MoveBlockRight :<C-u> silent call vim_move#MoveBlockHorizontally(v:count1)<CR>
vnoremap <silent> <Plug>MoveBlockLeft :<C-u> silent call vim_move#MoveBlockHorizontally(-v:count1)<CR>

nnoremap <silent> <Plug>MoveLineHalfPageDown :<C-u> silent call vim_move#MoveLineVertically(v:count1 * <SID>GetHalfPageSize())<CR>
nnoremap <silent> <Plug>MoveLineHalfPageUp :<C-u> silent call vim_move#MoveLineVertically(-v:count1 * <SID>GetHalfPageSize())<CR>
nnoremap <silent> <Plug>MoveLineDown :<C-u> silent call vim_move#MoveLineVertically(v:count1)<CR>
nnoremap <silent> <Plug>MoveLineUp :<C-u> silent call vim_move#MoveLineVertically(-v:count1)<CR>
nnoremap <silent> <Plug>MoveCharRight :<C-u> silent call vim_move#MoveCharHorizontally(v:count1)<CR>
nnoremap <silent> <Plug>MoveCharLeft :<C-u> silent call vim_move#MoveCharHorizontally(-v:count1)<CR>

execute 'vmap' '<A-D>' '<Plug>MoveBlockHalfPageDown'
execute 'vmap' '<A-U>' '<Plug>MoveBlockHalfPageUp'
execute 'vmap' '<A-J>' '<Plug>MoveBlockDown'
execute 'vmap' '<A-K>' '<Plug>MoveBlockUp'
execute 'vmap' '<A-H>' '<Plug>MoveBlockLeft'
execute 'vmap' '<A-L>' '<Plug>MoveBlockRight'

execute 'nmap' '<A-D>' '<Plug>MoveLineHalfPageDown'
execute 'nmap' '<A-U>' '<Plug>MoveLineHalfPageUp'
execute 'nmap' '<A-J>' '<Plug>MoveLineDown'
execute 'nmap' '<A-K>' '<Plug>MoveLineUp'
execute 'nmap' '<A-H>' '<Plug>MoveCharLeft'
execute 'nmap' '<A-L>' '<Plug>MoveCharRight'

"================================================================================#
"                             Highlighted yank                                   #
"================================================================================#

function! s:DefaultHighlight() abort
  highlight default link Yank Visual
endfunction

call s:DefaultHighlight()

augroup vim_utilities_highlighted_yank
  autocmd!
  autocmd ColorScheme * call s:DefaultHighlight()
  autocmd TextYankPost * call highlighted_yank#HighlightedYank(v:event.regtype)
augroup END

"================================================================================#
"                                Cursor word                                     #
"================================================================================#

augroup vim_utilities_cursor_word_highlight
  autocmd!
  if has('vim_starting')
    autocmd VimEnter * call cursor_word#CursorWordHighlight() |
          \ autocmd vim_utilities_cursor_word_highlight WinEnter,BufEnter * call cursor_word#MatchAdd()
  else
    call cursor_word#CursorWordHighlight()
    autocmd WinEnter,BufEnter * call cursor_word#MatchAdd()
  endif
  autocmd ColorScheme * call cursor_word#CursorWordHighlight()
  autocmd CursorMoved,CursorMovedI * call cursor_word#CursorMoved()
  autocmd InsertEnter * call cursor_word#MatchAdd(1)
  autocmd InsertLeave * call cursor_word#MatchAdd(0)
augroup END

"================================================================================#
"                                    End                                         #
"================================================================================#

let &cpo = s:cpo_save
unlet s:cpo_save

