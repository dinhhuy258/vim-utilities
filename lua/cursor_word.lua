local M = {}

local DISABLED = 0
local CURSOR = 1
local WINDOW = 2
local status = CURSOR

vim.o.cursorline = true

local function return_highlight_term(group, term)
  local output = vim.api.nvim_exec("highlight " .. group, true)
  return vim.fn.matchstr(output, term .. [[=\zs\S*]])
end

local normal_bg = return_highlight_term("Normal", "guibg")

function M.highlight_cursorword()
  if vim.g.cursorword_highlight ~= false then
    vim.cmd("highlight CursorWord gui=underline")
  end
end

function M.matchadd()
  if vim.bo.buftype ~= "" and vim.bo.buftype ~= "acwrite" then
    return
  end

  if vim.fn.hlexists("CursorWord") == 0 then
    return
  end
  local column = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local cursorword =
    vim.fn.matchstr(line:sub(1, column + 1), [[\k*$]]) .. vim.fn.matchstr(line:sub(column + 1), [[^\k*]]):sub(2)

  if cursorword == vim.w.cursorword then
    return
  end
  vim.w.cursorword = cursorword
  if vim.w.cursorword_match == 1 then
    vim.call("matchdelete", vim.w.cursorword_id)
  end
  vim.w.cursorword_match = 0
  if cursorword == "" or #cursorword > 32 or string.find(cursorword, "[\192-\255]+") ~= nil then
    return
  end
  local pattern = [[\<]] .. cursorword .. [[\>]]
  vim.w.cursorword_id = vim.fn.matchadd("CursorWord", pattern, -1)
  vim.w.cursorword_match = 1
end

function M.cursor_moved()
  M.matchadd()
  if status == WINDOW then
    status = CURSOR
    return
  end

  if status == CURSOR then
    vim.cmd("highlight! CursorLine guibg=" .. normal_bg)
    vim.cmd("highlight! CursorLineNr guibg=" .. normal_bg)
    status = DISABLED
  end
end

function M.win_enter()
  vim.o.cursorline = true
  status = WINDOW
end

function M.win_leave()
  vim.o.cursorline = false
  status = WINDOW
end

return M

