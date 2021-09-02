local M = {}

local config = {
  lua = { "stylua", "--search-parent-directories", "-" },
}

local handle_job_data = function(data)
  if not data then
    return nil
  end
  if data[#data] == "" then
    table.remove(data, #data)
  end
  if #data < 1 then
    return nil
  end
  return data
end

function M.is_supported(filetype)
  return config[filetype] ~= nil
end

function M.format()
  local modifiable = vim.bo.modifiable
  if not modifiable then
    vim.notify "[vim-utilities] Buffer is not modifiable"
    return
  end

  local filetype = vim.bo.filetype
  local formatters = config[filetype]
  if formatters == nil then
    vim.notify("[vim-utilities] No formatter found for filetype " .. filetype)
    return
  end

  local job_id = vim.fn.jobstart(formatters, {
    on_stdout = function(_, data, _)
      data = handle_job_data(data)
      if not data then
        return
      end

      vim.api.nvim_buf_set_lines(0, 0, -1, false, data)
      vim.api.nvim_command "write"
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })

  vim.fn.chansend(job_id, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  vim.fn.chanclose(job_id, "stdin")
end

return M
