local function highlighted_yank()
  local event = vim.api.nvim_get_vvar('event')
  if event.operator ~= 'y' or event.regtype == '' then
    return
  end

  local buffer = vim.call('bufnr', '%')
  local namespace = vim.api.nvim_create_namespace('')
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)

  local _, lnum1, col1, off1 = unpack(vim.call('getpos', '\'['))
  lnum1 = lnum1 - 1
  col1 = col1 - 1

  local _, lnum2, col2, off2 = unpack(vim.call('getpos', '\']'))
  lnum2 = lnum2 - 1
  col2 = col2 - 1

  for line = lnum1, (lnum1 + (lnum2 - lnum1)) do
    local is_first = (line == lnum1)
    local is_last = (line == lnum2)

    local c1
    if is_first == true then
      c1 = (col1 + off1)
    else
      c1 = 0
    end

    local c2
    if is_last == true then
      c2 = (col2 + off2)
    else
      c2 = -1
    end

    vim.api.nvim_buf_add_highlight(buffer, namespace, 'Yank', line, c1, c2)
  end

  vim.fn.timer_start(1000, function(timer)
      vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
    end)
end

return {
  highlighted_yank = highlighted_yank
}

