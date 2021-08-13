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

" Reference: https://github.com/bronson/vim-visual-star-search

function! s:VisualSetSearch(cmdtype, ...) abort
  let temp = @"
  normal! gvy
  if !a:0 || a:1 != 'raw'
    let @" = escape(@", a:cmdtype.'\*')
  endif
  let @/ = substitute(@", '\n', '\\n', 'g')
  let @/ = substitute(@/, '\[', '\\[', 'g')
  let @/ = substitute(@/, '\~', '\\~', 'g')
  let @/ = substitute(@/, '\.', '\\.', 'g')
  let @" = temp
endfunction

xnoremap * :<C-u>call <SID>VisualSetSearch('/')<CR>/<C-R>=@/<CR><CR>
xnoremap # :<C-u>call <SID>VisualSetSearch('?')<CR>?<C-R>=@/<CR><CR>

"================================================================================#
"                                 Floaterm                                       #
"================================================================================#

command! -nargs=1 FloatermNew lua require'floaterm'.new_floaterm(<q-args>)

command! FloatermToggle lua require'floaterm'.toggle_floaterm()
nnoremap <Leader>tt :FloatermToggle<CR>
tnoremap <Leader>tt <C-\><C-n>:FloatermToggle<CR>

command! FloatermKill lua require'floaterm'.kill_floaterm()
nnoremap <Leader>tk :FloatermKill<CR>
tnoremap <Leader>tk <C-\><C-n>:FloatermKill<CR>

nnoremap <Leader>tg :FloatermNew lazygit<CR>
tnoremap <Leader>tg <C-\><C-n>:FloatermNew lazygit<CR>

"================================================================================#
"                                   Git                                          #
"================================================================================#

command! GitCheckoutLocalBranch FloatermNew 'git checkout $(git branch | fzf)'
command! GitCheckoutRemoteBranch FloatermNew 'git checkout --track $(git branch --all | fzf)'
nnoremap <Leader>gc :GitCheckoutLocalBranch<CR>
tnoremap <Leader>gc <C-\><C-n>:GitCheckoutLocalBranch<CR>
nnoremap <Leader>gC :GitCheckoutRemoteBranch<CR>
tnoremap <Leader>gC <C-\><C-n>:GitCheckoutRemoteBranch<CR>

"================================================================================#
"                               Miscellaneous                                    #
"================================================================================#

" Last cmd utils
function! SaveToLastCmd(cmd) abort
  execute "silent !echo '" . a:cmd . "' > ~/.lastcmd"
endfunction
nnoremap <Leader>lt :FloatermNew '~/.lastcmd; read'<CR>

" Remove trailing whitespaces
command! FixWhitespace :%s/\s\+$//e

" Convert tab to space
command! ConvertTabToSpace :%s/\t/    /g

" Profiling
command! StartProfiling profile start ~/.profile.log | profile func * | profile file * | echo 'Profiling started'

"================================================================================#
"                                    End                                         #
"================================================================================#

let &cpo = s:cpo_save
unlet s:cpo_save

