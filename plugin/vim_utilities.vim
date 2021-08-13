if exists('s:vim_utilities_loaded')
   finish
endif
let s:vim_utilities_loaded = 1

let s:cpo_save = &cpo
set cpo&vim

lua require'nohlsearch'.setup()
lua require'cutlass'.setup()
lua require'cursor_word'.setup()
lua require'open'.setup()
lua require'floaterm'.setup()
lua require'visual_star_search'.setup()
lua require'lastcmd'.setup()

let &cpo = s:cpo_save
unlet s:cpo_save

