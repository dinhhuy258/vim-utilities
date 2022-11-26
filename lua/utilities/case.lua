local M = {}

M.state = {
  current_method = nil,
  buffer = nil,
}

local methods = {}

local codes = {
  a = string.byte "a",
  z = string.byte "z",
  A = string.byte "A",
  Z = string.byte "Z",
}

local function map(tbl, f)
  local t = {}

  for k, v in pairs(tbl) do
    t[k] = f(v)
  end

  return t
end

local function untrim_str(str, trim_info)
  return trim_info.start_trim .. str .. trim_info.end_trim
end

local function trim_str(str, _trimmable_chars)
  local chars = vim.split(str, "")
  local startCount = 0
  local endCount = 0
  local trimmable_chars = _trimmable_chars or { " ", "'", '"', "{", "}", "," }
  local trimmable_chars_by_char = {}

  for i = 1, #trimmable_chars, 1 do
    local trim_char = trimmable_chars[i]
    trimmable_chars_by_char[trim_char] = trim_char
  end

  local is_trimmable = function(char)
    return trimmable_chars_by_char[char]
  end

  for i = 1, #chars, 1 do
    local char = chars[i]
    if is_trimmable(char) then
      startCount = startCount + 1
    else
      break
    end
  end

  for i = #str, startCount + 1, -1 do
    local char = chars[i]
    if is_trimmable(char) then
      endCount = endCount + 1
    else
      break
    end
  end

  local trim_info = {
    start_trim = string.sub(str, 1, startCount),
    end_trim = string.sub(str, #chars - endCount + 1),
  }

  local trimmed_str = string.sub(str, startCount + 1, #chars - endCount) or ""

  return trim_info, trimmed_str
end

local function smart_analysis(str)
  local has_lower_case_characters = false
  local has_upper_case_characters = false
  local separators_dict = {}
  local separators = {}

  for current in str:gmatch "." do
    local code = string.byte(current)
    local is_lower = code >= codes.a and code <= codes.z
    local is_upper = code >= codes.A and code <= codes.Z

    if is_lower then
      has_lower_case_characters = true
    end
    if is_upper then
      has_upper_case_characters = true
    end

    if current == "." or current == "-" or current == "_" or current == " " then
      if separators_dict[current] == nil then
        separators_dict[current] = current
        table.insert(separators, current)
      end
    end
  end

  return has_lower_case_characters, has_upper_case_characters, separators
end

local function to_dash_case(_str)
  local previous = nil
  local items = {}

  local trim_info, str = trim_str(_str)

  local ends_with_space = string.sub(str, -1) == " "
  local has_lower_case_characters, _, separators = smart_analysis(str)

  for current in str:gmatch "." do
    local previous_code = previous and string.byte(previous) or 0
    local current_code = string.byte(current)

    local is_previous_lower = previous_code >= codes.a and previous_code <= codes.z
    local is_previous_upper = previous_code >= codes.A and previous_code <= codes.Z
    local is_current_lower = current_code >= codes.a and current_code <= codes.z
    local is_current_upper = current_code >= codes.A and current_code <= codes.Z

    local is_previous_alphabet = is_previous_lower or is_previous_upper
    local current_can_continue_word = is_current_lower
      or (is_current_upper and not has_lower_case_characters and #separators > 0)

    if previous == nil or (is_previous_alphabet and not current_can_continue_word) then
      table.insert(items, "")
    end

    if is_current_upper or is_current_lower then
      items[#items] = items[#items] .. current
    end

    previous = current
  end

  local result = table.concat(map({ unpack(items, 1, ends_with_space and (#items - 1) or #items) }, string.lower), "-")
    .. (ends_with_space and " " or "")

  return untrim_str(result, trim_info)
end

local function to_title(str)
  return string.sub(str, 1, 1):upper() .. string.sub(str, 2):lower()
end

local function to_pascal_case(str)
  local parts = vim.split(to_dash_case(str), "-")
  return table.concat(map(parts, to_title), "")
end

local function to_camel_case(str)
  local parts = vim.split(to_dash_case(str), "-")
  if #parts == 1 then
    return parts[1]:lower()
  end
  if #parts > 1 then
    return parts[1]:lower() .. table.concat(map({ unpack(parts, 2) }, to_title), "")
  end

  return ""
end

local function to_snake_case(str)
  local parts = vim.split(to_dash_case(str), "-")
  return table.concat(parts, "_")
end

local function to_upper_case(str)
  return to_dash_case(str):upper():gsub("-", "_")
end

local function to_dot_case(str)
  local parts = vim.split(to_dash_case(str), "-")
  return table.concat(parts, ".")
end

local function to_path_case(str)
  local parts = vim.split(to_dash_case(str), "-")
  return table.concat(parts, "/")
end

local function nvim_buf_get_text(buffer, start_row, start_col, end_row, end_col)
  local lines = vim.api.nvim_buf_get_lines(buffer, start_row, end_row + 1, false)

  lines[vim.tbl_count(lines)] = string.sub(lines[vim.tbl_count(lines)], 0, end_col)
  lines[1] = string.sub(lines[1], start_col + 1)

  return lines
end

local function do_substitution(start_row, start_col, end_row, end_col, method, buf)
  buf = buf or 0
  local lines = nvim_buf_get_text(buf, start_row - 1, start_col - 1, end_row - 1, end_col)

  local transformed = map(lines, method)

  local cursor_pos = vim.fn.getpos "."
  vim.api.nvim_buf_set_text(buf, start_row - 1, start_col - 1, end_row - 1, end_col, transformed)
  local new_cursor_pos = cursor_pos
  if cursor_pos[1] ~= start_row or (cursor_pos[2] < start_col) then
    new_cursor_pos = { 0, start_row, start_col }
  end
  vim.fn.setpos(".", new_cursor_pos)
end

function M.convert_case(case)
  M.state.current_method = methods[case]
  M.state.buffer = vim.api.nvim_get_current_buf()

  vim.o.operatorfunc = "v:lua.require'utilities.case'.operator_callback"
  vim.api.nvim_feedkeys("g@aw", "i", false)
end

function M.operator_callback(_)
  local sln = vim.api.nvim_buf_get_mark(M.state.buffer or 0, "[")
  local eln = vim.api.nvim_buf_get_mark(M.state.buffer or 0, "]")

  local start_row = sln[1]
  local start_col = sln[2] + 1
  local end_row = eln[1]
  local end_col = math.min(eln[2], vim.fn.getline(eln[1]):len()) + 1

  do_substitution(start_row, start_col, end_row, end_col, M.state.current_method, M.state.buffer)
end

function M.setup()
  methods["snake_case"] = to_snake_case
  methods["pascal_case"] = to_pascal_case
  methods["camel_case"] = to_camel_case
  methods["upper_case"] = to_upper_case
  methods["dash_case"] = to_dash_case
  methods["dot_case"] = to_dot_case
  methods["path_case"] = to_path_case

  vim.api.nvim_set_keymap("n", "crs", "<CMD>lua require('utilities.case').convert_case('snake_case')<CR>", {
    noremap = true,
    silent = true,
  })
  vim.api.nvim_set_keymap("n", "crp", "<CMD>lua require('utilities.case').convert_case('pascal_case')<CR>", {
    noremap = true,
    silent = true,
  })
  vim.api.nvim_set_keymap("n", "crc", "<CMD>lua require('utilities.case').convert_case('camel_case')<CR>", {
    noremap = true,
    silent = true,
  })
  vim.api.nvim_set_keymap("n", "cru", "<CMD>lua require('utilities.case').convert_case('upper_case')<CR>", {
    noremap = true,
    silent = true,
  })
  vim.api.nvim_set_keymap("n", "cr-", "<CMD>lua require('utilities.case').convert_case('dash_case')<CR>", {
    noremap = true,
    silent = true,
  })
  vim.api.nvim_set_keymap("n", "cr.", "<CMD>lua require('utilities.case').convert_case('dot_case')<CR>", {
    noremap = true,
    silent = true,
  })
  vim.api.nvim_set_keymap("n", "cr/", "<CMD>lua require('utilities.case').convert_case('path_case')<CR>", {
    noremap = true,
    silent = true,
  })
end

return M
