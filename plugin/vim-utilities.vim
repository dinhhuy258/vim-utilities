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

" Reference: https://github.com/matze/vim-move

function! s:MoveVertically(first, last, distance) abort
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

function! s:MoveLineVertically(distance) abort
  let l:old_col    = col('.')
  normal! ^
  let l:old_indent = col('.')

  call s:MoveVertically('.', '.', a:distance)

  normal! ^
  let l:new_indent = col('.')
  call cursor(line('.'), max([1, l:old_col - l:old_indent + l:new_indent]))
endfunction

function! s:MoveBlockVertically(distance) abort
  call s:MoveVertically("'<", "'>", a:distance)
  normal! gv
endfunction

function! s:MoveHorizontally(corner_start, corner_end, distance) abort
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

function! s:MoveCharHorizontally(distance) abort
  call s:MoveHorizontally('.', '.', a:distance)
endfunction

function! s:MoveBlockHorizontally(distance) abort
  execute "normal! g`<\<C-v>g`>"
  if s:MoveHorizontally("'<", "'>", a:distance)
    execute "normal! g`[\<C-v>g`]"
  endif
endfunction

function s:GetHalfPageSize() abort
  return winheight('.') / 2
endfunction

vnoremap <silent> <Plug>MoveBlockHalfPageDown :<C-u> silent call <SID>MoveBlockVertically(v:count1 * <SID>GetHalfPageSize())<CR>
vnoremap <silent> <Plug>MoveBlockHalfPageUp :<C-u> silent call <SID>MoveBlockVertically(-v:count1 * <SID>GetHalfPageSize())<CR>
vnoremap <silent> <Plug>MoveBlockDown :<C-u> silent call <SID>MoveBlockVertically(v:count1)<CR>
vnoremap <silent> <Plug>MoveBlockUp :<C-u> silent call <SID>MoveBlockVertically(-v:count1)<CR>
vnoremap <silent> <Plug>MoveBlockRight :<C-u> silent call <SID>MoveBlockHorizontally(v:count1)<CR>
vnoremap <silent> <Plug>MoveBlockLeft :<C-u> silent call <SID>MoveBlockHorizontally(-v:count1)<CR>

nnoremap <silent> <Plug>MoveLineHalfPageDown :<C-u> silent call <SID>MoveLineVertically(v:count1 * <SID>GetHalfPageSize())<CR>
nnoremap <silent> <Plug>MoveLineHalfPageUp :<C-u> silent call <SID>MoveLineVertically(-v:count1 * <SID>GetHalfPageSize())<CR>
nnoremap <silent> <Plug>MoveLineDown :<C-u> silent call <SID>MoveLineVertically(v:count1)<CR>
nnoremap <silent> <Plug>MoveLineUp :<C-u> silent call <SID>MoveLineVertically(-v:count1)<CR>
nnoremap <silent> <Plug>MoveCharRight :<C-u> silent call <SID>MoveCharHorizontally(v:count1)<CR>
nnoremap <silent> <Plug>MoveCharLeft :<C-u> silent call <SID>MoveCharHorizontally(-v:count1)<CR>

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
"                                    End                                         #
"================================================================================#

let &cpo = s:cpo_save
unlet s:cpo_save

