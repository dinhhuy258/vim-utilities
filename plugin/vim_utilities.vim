if exists('s:vim_utilities_loaded')
   finish
endif
let s:vim_utilities_loaded = 1

let s:cpo_save = &cpo
set cpo&vim

"================================================================================#
"                              Highlight search                                  #
"================================================================================#

lua require'nohlsearch'.setup()

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
"                                Cursor word                                     #
"================================================================================#

lua require'cursor_word'.setup()

"================================================================================#
"                                 Open file                                      #
"================================================================================#

nnoremap <silent>gof :<C-u>call open#File("%:p")<CR>
nnoremap <silent>goF :<C-u>call open#File(getcwd())<CR>

"================================================================================#
"                               Visual searh                                     #
"================================================================================#

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

" Copy utils
nnoremap cpf :let @+ = expand("%:p")<CR>
nnoremap cpr :let @+ = fnamemodify(expand("%"), ":~:.")<CR>
nnoremap cpg :let @+ = system("git rev-parse --abbrev-ref HEAD")<CR>

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

