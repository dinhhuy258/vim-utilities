local M = {}

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

local head_cache = {}

local function parent_pathname(path)
  local i = path:find "[\\/:][^\\/:]*$"
  if not i then
    return
  end
  return path:sub(1, i - 1)
end

-- Checks if provided directory contains git directory
local function has_git_dir(dir)
  local git_dir = dir .. "/.git"
  if vim.fn.isdirectory(git_dir) == 1 then
    return git_dir
  end
end

-- Get git directory from git file if present
local function has_git_file(dir)
  local gitfile = io.open(dir .. "/.git")
  if gitfile ~= nil then
    local git_dir = gitfile:read():match "gitdir: (.*)"
    gitfile:close()

    return git_dir
  end
end

-- Check if git directory is absolute path or a relative
local function is_path_absolute(dir)
  local patterns = {
    "^/", -- unix
    "^%a:[/\\]", -- windows
  }
  for _, pattern in ipairs(patterns) do
    if string.find(dir, pattern) then
      return true
    end
  end
  return false
end

local function get_git_dir(path)
  -- If path nil or '.' get the absolute path to current directory
  if not path or path == "." then
    path = vim.fn.getcwd()
  end

  local git_dir
  -- Check in each path for a git directory, continues until found or reached
  -- root directory
  while path do
    -- Try to get the git directory checking if it exists or from a git file
    git_dir = has_git_dir(path) or has_git_file(path)
    if git_dir ~= nil then
      break
    end
    -- Move to the parent directory, nil if there is none
    path = parent_pathname(path)
  end

  if not git_dir then
    return
  end

  if is_path_absolute(git_dir) then
    return git_dir
  end
  return path .. "/" .. git_dir
end

local function check_git_workspace()
  if vim.bo.buftype == "terminal" then
    return false
  end
  local current_file = vim.fn.expand "%:p"
  local current_dir
  -- if file is a symlinks
  if vim.fn.getftype(current_file) == "link" then
    local real_file = vim.fn.resolve(current_file)
    current_dir = vim.fn.fnamemodify(real_file, ":h")
  else
    current_dir = vim.fn.expand "%:p:h"
  end
  local result = get_git_dir(current_dir)
  if not result then
    return false
  end
  return true
end

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

local function get_git_detached_head()
  local git_branches_file = io.popen("git branch -a --no-abbrev --contains", "r")
  if not git_branches_file then
    return
  end
  local git_branches_data = git_branches_file:read "*l"
  io.close(git_branches_file)
  if not git_branches_data then
    return
  end

  local branch_name = git_branches_data:match ".*HEAD (detached %w+ [%w/-]+)"
  if branch_name and string.len(branch_name) > 0 then
    return branch_name
  end
end

local function get_git_branch()
  if vim.bo.filetype == "help" then
    return
  end
  local current_file = vim.fn.expand "%:p"
  local current_dir

  -- If file is a symlinks
  if vim.fn.getftype(current_file) == "link" then
    local real_file = vim.fn.resolve(current_file)
    current_dir = vim.fn.fnamemodify(real_file, ":h")
  else
    current_dir = vim.fn.expand "%:p:h"
  end

  local git_dir = get_git_dir(current_dir)
  if not git_dir then
    return
  end

  -- The function get_git_dir should return the root git path with '.git'
  -- appended to it. Otherwise if a different gitdir is set this substitution
  -- doesn't change the root.
  local git_root = git_dir:gsub("/.git/?$", "")
  local head_stat = vim.loop.fs_stat(git_dir .. "/HEAD")

  if head_stat and head_stat.mtime then
    if head_cache[git_root] and head_cache[git_root].mtime == head_stat.mtime.sec and head_cache[git_root].branch then
      return head_cache[git_root].branch
    else
      local head_file = vim.loop.fs_open(git_dir .. "/HEAD", "r", 438)
      if not head_file then
        return
      end
      local head_data = vim.loop.fs_read(head_file, head_stat.size, 0)
      if not head_data then
        return
      end
      vim.loop.fs_close(head_file)

      head_cache[git_root] = {
        head = head_data,
        mtime = head_stat.mtime.sec,
      }
    end
  else
    return
  end

  local branch_name = head_cache[git_root].head:match "ref: refs/heads/([^\n\r%s]+)"
  if not branch_name then
    -- check if detached head
    branch_name = get_git_detached_head()
    if not branch_name then
      return
    end
  end

  head_cache[git_root].branch = branch_name
  return branch_name
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
  if not check_git_workspace() then
    return ""
  end

  return " " .. get_git_branch()
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

function M.get_statusline(active)
  local statusline = ""

  local special_filetype = special_filetypes[vim.bo.ft]
  if special_filetype then
    -- Section left
    statusline = statusline .. separator_provider " "
    statusline = statusline .. special_filetype_provider(special_filetype)

    if not special_filetype.show_section_right then
      return statusline
    end
  end

  if not active then
    return statusline
  end

  -- Section left
  statusline = statusline .. separator_provider " "
  statusline = statusline .. file_info_provider()

  -- Section right
  statusline = statusline .. "%="
  statusline = statusline .. git_branch_provider()
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
