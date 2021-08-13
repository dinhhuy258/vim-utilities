local M = {}

vim.w.cursorword_match = false

function M.matchdelete()
  if vim.w.cursorword_match then
    vim.call("matchdelete", vim.w.cursorword_id)
  end

  vim.w.cursorword_match = false
end

function M.matchadd()
  if vim.bo.buftype ~= "" and vim.bo.buftype ~= "acwrite" then
    return
  end

  local column = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local cursorword = vim.fn.matchstr(line:sub(1, column + 1), [[\k*$]])
    .. vim.fn.matchstr(line:sub(column + 1), [[^\k*]]):sub(2)

  if cursorword == vim.w.cursorword then
    return
  end

  M.matchdelete()

  vim.w.cursorword = cursorword

  if cursorword == "" or #cursorword > 100 or string.find(cursorword, "[\192-\255]+") ~= nil then
    return
  end

  local pattern = [[\<]] .. cursorword .. [[\>]]
  vim.w.cursorword_id = vim.fn.matchadd("CursorWord", pattern, -1)
  vim.w.cursorword_match = true
end

function M.setup()
  vim.api.nvim_command "highlight CursorWord gui=underline"
  vim.api.nvim_command "autocmd CursorMoved,InsertLeave * lua require'utilities.cursor_word'.matchadd()"
  vim.api.nvim_command "autocmd InsertEnter * lua require'utilities.cursor_word'.matchdelete()"
end

return M
