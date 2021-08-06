local floaterm_buf, floaterm_win

local function try_open(win_id)
  return vim.fn.win_gotoid(win_id) > 0
end

local function is_open()
    if not floaterm_win then
        return false
    end

    local win_open = try_open(floaterm_win)
    return win_open and vim.api.nvim_win_get_buf(floaterm_win) == floaterm_buf
end

local function kill_floaterm()
  if floaterm_buf ~= nil then
    if vim.fn.win_gotoid(floaterm_win) ~= 0 then
      vim.api.nvim_win_close(floaterm_win, true)
    end

    if vim.call('bufexists', floaterm_buf) ~= 0 then
      vim.api.nvim_command('silent bwipeout! '..floaterm_buf)
    end

    floaterm_win = nil
    floaterm_buf = nil
  end

  vim.api.nvim_command('silent checktime')
end

local function open_floaterm(cmd)
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local floaterm_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    anchor = "NW",
    border = "single"
  }

  if floaterm_buf ~= nil then
    if vim.fn.win_gotoid(floaterm_buf) == 0 and vim.call('bufexists', floaterm_buf) ~= 0 then
      floaterm_win = vim.api.nvim_open_win(floaterm_buf, true, floaterm_opts)
      vim.api.nvim_command('startinsert')
      return
    else
      kill_floaterm()
    end
  end

  floaterm_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(floaterm_buf, 'buftype', '')
  vim.api.nvim_buf_set_option(floaterm_buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(floaterm_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(floaterm_buf, 'filetype', 'floaterm')

  floaterm_win = vim.api.nvim_open_win(floaterm_buf, true, floaterm_opts)
  vim.api.nvim_win_set_option(floaterm_win, 'winhl', 'Normal:Normal')
  vim.api.nvim_win_set_option(floaterm_win, 'cursorline', true)
  vim.api.nvim_win_set_option(floaterm_win, 'colorcolumn', "")

  if cmd ~= nil then
    vim.call('termopen', 'bash -c ' .. cmd)
  else
    vim.api.nvim_command('terminal')
  end
  vim.api.nvim_command('startinsert')
  -- This option should be set after terminal command
  vim.api.nvim_buf_set_option(floaterm_buf, 'buflisted', false)

  vim.api.nvim_command('autocmd TermClose <buffer> ++once lua require\'floaterm\'.kill_floaterm()')
end

local function hide_floaterm()
  if floaterm_win ~= nil and vim.fn.win_gotoid(floaterm_win) ~= 0 then
    vim.fn.win_gotoid(floaterm_win)
    vim.api.nvim_command('hide')
  end

  floaterm_win = nil
end

local function new_floaterm(cmd)
  kill_floaterm()
  open_floaterm(cmd)
end

local function toggle_floaterm()
  if floaterm_win == nil then
    open_floaterm()
  else
    hide_floaterm()
    vim.api.nvim_command('silent checktime')
  end
end

return {
  new_floaterm = new_floaterm,
  toggle_floaterm = toggle_floaterm,
  kill_floaterm = kill_floaterm
}

