let s:cpo_save = &cpo
set cpo&vim

function! buffer#CloseAllExceptCurrentBuffer() abort
  let l:last_buffer = bufnr('$')
  let l:current_buffer = bufnr('%')
  let l:buffer = 1
  while l:buffer <= l:last_buffer
    if l:buffer != l:current_buffer && buflisted(l:buffer)
      silent exe 'bdel! ' . l:buffer
    endif
    let l:buffer = l:buffer + 1
  endwhile
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

