local M = {}

function M.stop_hlsearch()
  local current_buf_ft = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win()), "ft")

  if vim.v.hlsearch == 1 and vim.fn.mode() == "n" and current_buf_ft ~= "fzf" then
    vim.fn.feedkeys "<vim_utilities>(stop_hightlight_search)"
  end
end

function M.start_hlsearch()
  vim.cmd [[
    if v:hlsearch && !search('\%#\zs'.@/,'cnW')
      call luaeval("require'utilities.nohlsearch'.stop_hlsearch()")
    endif
  ]]
end

function M.setup()
  vim.cmd "noremap <silent> <vim_utilities>(stop_hightlight_search) :<C-U>nohlsearch<CR>"
  vim.cmd "noremap! <expr> <vim_utilities>(stop_hightlight_search) execute('nohlsearch')[-1]"

  vim.cmd "augroup vim_utilities_nohlsearch"
  vim.cmd "autocmd!"

  vim.cmd "autocmd CursorMoved * call luaeval(\"require'utilities.nohlsearch'.start_hlsearch()\")"
  vim.cmd "autocmd InsertEnter * call luaeval(\"require'utilities.nohlsearch'.stop_hlsearch()\")"

  vim.cmd "augroup END"
end

return M
