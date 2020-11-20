local function close_all_except_current_buffer()
  local last_buffer = vim.call('bufnr', '$')
  local current_buffer = vim.call('bufnr', '%')
  local buffer = 1
  while buffer <= last_buffer do
    if buffer ~= current_buffer and vim.call('buflisted', buffer) ~= 0 then
      vim.api.nvim_command('silent bdel! '..buffer)
    end
    buffer = buffer + 1
  end
end

return {
  close_all_except_current_buffer = close_all_except_current_buffer
}

