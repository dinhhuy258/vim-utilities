local M = {}

local lastcmd_file = "~/.lastcmd"

function M.save_to_lastcmd(cmd)
  if vim.loop.fs_access(lastcmd_file, "r") == false then
    vim.fn.system("touch " .. lastcmd_file)
    vim.fn.system("chmod +x " .. lastcmd_file)
  end

  vim.api.nvim_command("silent !echo '" .. cmd .. "' > ~/.lastcmd")
end

function M.setup()
  vim.api.nvim_set_keymap(
    "n",
    "<Leader>lt",
    "<CMD>lua require('utilities.floaterm').new_floaterm('~/.lastcmd; read')<CR>",
    {
      noremap = true,
      silent = true,
    }
  )
end

return M
