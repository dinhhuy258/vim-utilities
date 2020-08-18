let s:cpo_save = &cpo
set cpo&vim

function! open#File(path)
  let l:path = substitute(expand(a:path, 1), '\\\\\+', '\', 'g')
  let l:dir = isdirectory(l:path) ? l:path : fnamemodify(l:path, ":h")
  let l:valid_file = filereadable(l:path)

  if !isdirectory(l:dir)
    " If the directory was moved/deleted
    echo '[vim-utilities] Invalid/ missing directory: ' . l:dir
    return
  endif

  if l:valid_file
    silent call system('open --reveal '.shellescape(l:path))
  else
    silent call system('open '.shellescape(l:dir))
  endif
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

