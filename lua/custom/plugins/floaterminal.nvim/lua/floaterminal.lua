vim.keymap.set('t', 'jk', '<c-\\><c-n>')

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

local function open_floating_window(opts)
  opts = opts or {}

  -- get current screen dimensions
  local columns = vim.o.columns
  local lines = vim.o.lines

  -- Calculate window dimensions (default 80% if not provided)
  local win_width = opts.width or math.floor(columns * 0.8)
  local win_height = opts.height or math.floor(lines * 0.8)

  -- Compute the position to center the window
  local col = math.floor((columns - win_width) / 2)
  local row = math.floor((lines - win_height) / 2)

  -- Create new unlisted buffer
  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  if not buf then
    error 'Failed to create buffer'
  end

  -- Open the floating window with styles/border
  local win_config = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
  }
  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

local toggle_terminal = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = open_floating_window { buf = state.floating.buf }
    if vim.bo[state.floating.buf].buftype ~= 'terminal' then
      vim.cmd.terminal()
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
  vim.cmd 'normal i'
end

vim.api.nvim_create_user_command('Floaterminal', toggle_terminal, {})
vim.keymap.set({ 'n', 't' }, '<space>tt', toggle_terminal)
