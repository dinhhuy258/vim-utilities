if exists('s:vim_utilities_loaded')
   finish
endif
let s:vim_utilities_loaded = 1

let s:cpo_save = &cpo
set cpo&vim

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
  autocmd CursorMoved * call cursor_word#CursorMoved()
  autocmd InsertLeave * call cursor_word#MatchAdd()
  autocmd InsertEnter * call cursor_word#MatchDelete()
augroup END

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
"                                 Commentary                                     #
"================================================================================#

xnoremap <expr>   <Plug>ToggleComment commentary#ToggleComment()
nnoremap <expr>   <Plug>ToggleCommentLine commentary#ToggleComment() . '_'

xmap <Leader>/  <Plug>ToggleComment
nmap <Leader>/  <Plug>ToggleCommentLine

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

augroup vim_utilities_floaterm
au!
au FileType floaterm tnoremap <C-c> <C-\><C-n>:FloatermKill<CR>
augroup END

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

" Ping cursor
" Reference: https://github.com/uptech/vim-ping-cursor

function! s:PingCursor() abort
  set cursorline cursorcolumn
  redraw
  execute 'sleep250m'
  set nocursorline nocursorcolumn
endfunction

nnoremap <silent> <Leader>p :call <SID>PingCursor()<CR>

" Last cmd utils
function! SaveToLastCmd(cmd) abort
  execute "silent !echo '" . a:cmd . "' > ~/.lastcmd"
endfunction
nnoremap <Leader>lt :FloatermNew '~/.lastcmd; read'<CR>

" Copy utils
nnoremap cpf :let @+ = expand("%:p")<CR>
nnoremap cpr :let @+ = expand("%")<CR>
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

