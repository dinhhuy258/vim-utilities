local M = {}

local function override_select_bindings()
  local i = 33

  -- Add a map for every printable character to copy to black hole register
  while i <= 126 do
    local char = string.char(i)
    vim.api.nvim_set_keymap("s", char, ' <c-o>"_c' .. char, {
      noremap = true,
      silent = true,
    })
    i = i + 1
  end

  vim.api.nvim_set_keymap("s", "<bs>", '<c-o>"_c', {
    noremap = true,
    silent = true,
  })
  vim.api.nvim_set_keymap("s", "<space>", '<c-o>"_c<space>', {
    noremap = true,
    silent = true,
  })
end

local function override_delete_and_change_bindings()
  local bindings = {
    { "c", '"_c', "nx" },
    { "cc", '"_S', "n" },
    { "C", '"_C', "nx" },
    { "s", '"_s', "nx" },
    { "S", '"_S', "nx" },
    { "d", '"_d', "nx" },
    { "dd", '"_dd', "n" },
    { "D", '"_D', "nx" },
    { "x", '"_x', "n" },
    { "X", '"_X', "nx" },
  }

  for _, binding in pairs(bindings) do
    binding[3]:gsub(".", function(mode)
      vim.api.nvim_set_keymap(mode, binding[1], binding[2], {
        noremap = true,
        silent = true,
      })
    end)
  end
end

function M.setup()
  override_delete_and_change_bindings()
  override_select_bindings()
end

return M
