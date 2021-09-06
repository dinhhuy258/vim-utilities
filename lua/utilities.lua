local M = {}

function M.setup()
  require("utilities.nohlsearch").setup()
  require("utilities.cutlass").setup()
  require("utilities.cursor_word").setup()
  require("utilities.open").setup()
  require("utilities.floaterm").setup()
  require("utilities.visual_star_search").setup()
  require("utilities.lastcmd").setup()
  require("utilities.formatter").setup()
  require("utilities.statusline").setup()
  require("utilities.numb").setup()
end

return M
