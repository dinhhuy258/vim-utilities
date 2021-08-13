local M = {}

function M.open_file(path)
  local dir = ""
  if vim.fn.isdirectory(path) then
    dir = path
  else
    dir = vim.fn.fnamemodify(path, ":h")
  end

  if not vim.fn.isdirectory(dir) then
    -- If the directory was moved/deleted
    vim.notify("[vim-utilities] Invalid/ missing directory: " .. dir)
  end

  if vim.fn.filereadable(path) then
    vim.fn.system("open --reveal " .. vim.fn.shellescape(path))
  else
    vim.fn.system("open " .. vim.fn.shellescape(dir))
  end
end

function M.setup()
  vim.api.nvim_set_keymap("n", "gof", "<CMD>lua require('open').open_file(vim.fn.expand('%:p'))<CR>", {
    noremap = true,
    silent = true,
  })
  vim.api.nvim_set_keymap("n", "goF", "<CMD>lua require('open').open_file(vim.fn.getcwd())<CR>", {
    noremap = true,
    silent = true,
  })
end

return M
