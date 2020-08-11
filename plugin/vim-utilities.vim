if exists('s:vim-utilities-loaded')
   finish
endif
let s:vim-utilities-loaded = 1

"================================================================================#
"                       Remove trailing whitespaces                              #
"================================================================================#

command! FixWhitespace :%s/\s\+$//e

"================================================================================#
"                    Boost performance for large buffer                          #
"================================================================================#

augroup boost_performance_for_large_buffer
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

