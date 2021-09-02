local M = {}

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
end

return M
