let s:cpo_save = &cpo
set cpo&vim

" Reference: https://github.com/justinmk/vim-highlightedyank

function! highlighted_yank#HighlightedYank(regtype) abort
  if v:event.operator !=# 'y' || v:event.regtype ==# ''
    return
  endif

  let l:bnr = bufnr('%')
  let l:ns = nvim_create_namespace('')
  call nvim_buf_clear_namespace(l:bnr, l:ns, 0, -1)

  let [_, l:lin1, l:col1, l:off1] = getpos("'[")
  let [l:lin1, l:col1] = [l:lin1 - 1, l:col1 - 1]
  let [_, l:lin2, l:col2, l:off2] = getpos("']")
  let [l:lin2, l:col2] = [l:lin2 - 1, l:col2]
  for l:l in range(l:lin1, l:lin1 + (l:lin2 - l:lin1))
    let l:is_first = (l == l:lin1)
    let l:is_last = (l == l:lin2)
    let l:c1 = l:is_first ? (l:col1 + l:off1) : 0
    let l:c2 = l:is_last ? (l:col2 + l:off2) : -1
    call nvim_buf_add_highlight(l:bnr, l:ns, 'Yank', l:l, l:c1, l:c2)
  endfor

  call timer_start(1000, {-> nvim_buf_clear_namespace(l:bnr, l:ns, 0, -1)})
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

