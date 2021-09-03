local M = {}

local mode_icons = {
  ["n"] = { icon = "" },
  ["v"] = { icon = "" },
  ["V"] = { icon = "" },
  ["i"] = { icon = "" },
  ["s"] = { icon = "" },
  ["S"] = { icon = "" },
  ["ic"] = { icon = "" },
  ["c"] = { icon = "" },
  ["r"] = { icon = "Prompt" },
  ["t"] = { icon = "" },
  ["R"] = { icon = "凜" },
  [""] = { icon = "" },
}

local special_filetypes = {
  NvimTree = {
    name = "File explorer",
    icon = "פּ",
    show_section_right = false,
  },
  fzf = {
    name = "fzf",
    icon = "",
    show_section_right = false,
  },
  VimDatabase = {
    name = "Database",
    icon = "",
    show_section_right = true,
  },
  floaterm = {
    name = "Terminal",
    icon = "",
    show_section_right = false,
  },
  packer = {
    name = "Packer",
    icon = "",
    show_section_right = false,
  },
  startify = {
    name = "Startify",
    icon = "",
    show_section_right = true,
  },
  help = {
    name = "Help",
    icon = "龎",
    show_section_right = true,
  },
}

local function buffer_is_empty()
  if vim.fn.empty(vim.fn.expand "%:t") ~= 1 then
    return false
  end
  return true
end

local function line_column_provider()
  local line = vim.fn.line "."
  local column = vim.fn.col "."
  return string.format("%3d :%2d ", line, column)
end

local function separator_provider(separator)
  return separator
end

local function file_info_provider()
  if buffer_is_empty() then
    return ""
  end

  local f_name = vim.fn.expand "%f"

  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return f_name
  end

  local icon, icon_hl = devicons.get_icon(vim.fn.expand "%:t", vim.fn.expand "%:e")

  if icon == nil then
    icon = " "
  else
    vim.cmd("hi StatuslineFileIcon guibg=NONE" .. " guifg=" .. vim.fn.synIDattr(vim.fn.hlID(icon_hl), "fg"))
    icon = "%#StatuslineFileIcon#" .. icon .. "%#StatusLine# "
  end

  return icon .. f_name
end

local function special_filetype_provider(special_filetype)
  return special_filetype.icon .. " " .. special_filetype.name
end

local function git_branch_provider()
  local gsd = vim.b.gitsigns_status_dict

  if gsd and gsd.head and #gsd.head > 0 then
    return " " .. gsd.head .. " |"
  end

  return ""
end

local function line_percent_provider()
  local current_line = vim.fn.line "."
  local total_line = vim.fn.line "$"
  if current_line == 1 then
    return " Top "
  elseif current_line == vim.fn.line "$" then
    return " Bot "
  end
  local result, _ = math.modf((current_line / total_line) * 100)
  return " " .. result .. "%% "
end

local function vim_mode_provider()
  local mode = mode_icons[vim.api.nvim_get_mode()["mode"]] or mode_icons["n"]

  return " " .. mode.icon .. " "
end

function M.get_statusline(active)
  local statusline = ""

  local special_filetype = special_filetypes[vim.bo.ft]
  if special_filetype then
    -- Section left
    statusline = statusline .. separator_provider " "
    statusline = statusline .. special_filetype_provider(special_filetype)

    if not active or not special_filetype.show_section_right then
      return statusline
    end
  elseif active then
    -- Section left
    statusline = statusline .. separator_provider " "
    statusline = statusline .. file_info_provider()
  else
    return statusline
  end

  -- Section right
  statusline = statusline .. "%="
  statusline = statusline .. git_branch_provider()
  statusline = statusline .. vim_mode_provider()
  statusline = statusline .. separator_provider " |"
  statusline = statusline .. line_column_provider()
  statusline = statusline .. separator_provider " |"
  statusline = statusline .. line_percent_provider()

  return statusline
end

function M.set_statusline()
  for _, win in pairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_get_current_win() == win then
      vim.wo[win].statusline = "%!v:lua.require'utilities.statusline'.get_statusline(v:true)"
    elseif vim.api.nvim_buf_get_name(0) ~= "" then
      vim.wo[win].statusline = "%!v:lua.require'utilities.statusline'.get_statusline(v:false)"
    end
  end
end

function M.setup()
  vim.cmd [[au BufEnter,BufWinEnter,WinEnter,BufReadPost * lua require'utilities.statusline'.set_statusline()]]
end

return M
