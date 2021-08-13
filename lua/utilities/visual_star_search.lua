local M = {}

function M.search()
  vim.cmd [[
    let temp = @"
    normal! gvy
    if !a:0 || a:1 != 'raw'
      let @" = escape(@", '/\*')
    endif
    let @/ = substitute(@", '\n', '\\n', 'g')
    let @/ = substitute(@/, '\[', '\\[', 'g')
    let @/ = substitute(@/, '\~', '\\~', 'g')
    let @/ = substitute(@/, '\.', '\\.', 'g')
    let @" = temp
  ]]
end

function M.setup()
  vim.cmd "xnoremap * :<C-u>call luaeval(\"require'utilities.visual_start_search'.search()\")<CR>/<C-R>=@/<CR><CR>"
end

return M
