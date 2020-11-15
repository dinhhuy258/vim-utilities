local floaterm_buf, floaterm_win

local function open_floaterm()
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(border_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(border_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(border_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(border_buf, 'buflisted', false)

  local border_lines = { '┌' .. string.rep('─', win_width) .. '┐' }
  local middle_line = '│' .. string.rep(' ', win_width) .. '│'
  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '└' .. string.rep('─', win_width) .. '┘')
  vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
  vim.api.nvim_buf_set_option(border_buf, 'modifiable', false)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1,
    anchor = "NW",
    focusable = false
  }

  local border_win = vim.api.nvim_open_win(border_buf, true, border_opts)
  vim.api.nvim_win_set_option(border_win, 'winhl', 'Normal:Normal')
  vim.api.nvim_win_set_option(border_win, 'cursorline', true)
  vim.api.nvim_win_set_option(border_win, 'colorcolumn', "")

  floaterm_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(floaterm_buf, 'buftype', '')
  vim.api.nvim_buf_set_option(floaterm_buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(floaterm_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(floaterm_buf, 'filetype', 'floaterm')

  local floaterm_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    anchor = "NW"
  }

  floaterm_win = vim.api.nvim_open_win(floaterm_buf, true, floaterm_opts)
  vim.api.nvim_win_set_option(floaterm_win, 'winhl', 'Normal:Normal')
  vim.api.nvim_win_set_option(floaterm_win, 'cursorline', true)
  vim.api.nvim_win_set_option(floaterm_win, 'colorcolumn', "")

  vim.api.nvim_command('terminal')
  vim.api.nvim_command('startinsert')
  -- This option should be set after terminal command
  vim.api.nvim_buf_set_option(floaterm_buf, 'buflisted', false)
  vim.api.nvim_command('autocmd BufHidden <buffer=' .. tostring(floaterm_buf) .. '> exe "silent bwipeout! "'..border_buf)
end

local function close_floaterm()
  if floaterm_win ~= nil then
    vim.api.nvim_win_close(floaterm_win, true)
    floaterm_win = nil
    floaterm_buf = nil
  end
end

local function toggle_floaterm()
  if floaterm_win == nil then
    open_floaterm()
  else
    close_floaterm()
  end
end

return {
  toggle_floaterm = toggle_floaterm
}

