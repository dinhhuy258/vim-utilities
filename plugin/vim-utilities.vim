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
"                                    End                                         #
"================================================================================#

let &cpo = s:cpo_save
unlet s:cpo_save

