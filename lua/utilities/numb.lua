local M = {}

local win_states = {}

local function peek(winnr, linenr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local n_buf_lines = vim.api.nvim_buf_line_count(bufnr)
  linenr = math.min(linenr, n_buf_lines)
  linenr = math.max(linenr, 1)

  -- Saving window state if this is a first call of peek()
  if not win_states[winnr] then
    win_states[winnr] = {
      cursor = vim.api.nvim_win_get_cursor(winnr),
    }
  end

  -- Setting the cursor
  local original_column = win_states[winnr].cursor[2]
  local peek_cursor = { linenr, original_column }
  vim.api.nvim_win_set_cursor(winnr, peek_cursor)
end

local function unpeek(winnr, stay)
  local orig_state = win_states[winnr]

  if not orig_state then
    return
  end

  if stay then
    -- Unfold at the cursorline if user wants to stay
    vim.cmd "normal! zv"
  else
    -- Rollback the cursor if the user does not want to stay
    vim.api.nvim_win_set_cursor(winnr, orig_state.cursor)
  end
  win_states[winnr] = nil
end

local function is_peeking(winnr)
  return win_states[winnr] and true or false
end

function M.on_cmdline_changed()
  local cmd_line = vim.api.nvim_call_function("getcmdline", {})
  local winnr = vim.api.nvim_get_current_win()
  local num_str = cmd_line:match "^%d+$"
  if num_str then
    peek(winnr, tonumber(num_str))
    vim.cmd "redraw"
  elseif is_peeking(winnr) then
    unpeek(winnr, false)
    vim.cmd "redraw"
  end
end

function M.on_cmdline_exit()
  local winnr = vim.api.nvim_get_current_win()
  if not is_peeking(winnr) then
    return
  end

  -- Stay if the user does not abort the cmdline
  local event = vim.api.nvim_get_vvar "event"
  local stay = not event.abort
  unpeek(winnr, stay)
end

function M.setup()
  vim.cmd [[ augroup utilities.numb ]]
  vim.cmd [[    autocmd! ]]
  vim.cmd [[    autocmd CmdlineChanged : lua require('utilities.numb').on_cmdline_changed() ]]
  vim.cmd [[    autocmd CmdlineLeave : lua require('utilities.numb').on_cmdline_exit() ]]
  vim.cmd [[ augroup END ]]
end

return M
