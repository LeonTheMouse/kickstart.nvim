local M = {}

local function open_floating_window(config)
  -- Create new unlisted buffer
  local buf = vim.api.nvim_create_buf(false, true)

  if not buf then
    error 'Failed to create buffer'
  end

  local win = vim.api.nvim_open_win(buf, true, config)

  return { buf = buf, win = win }
end

M.setup = function()
  --nothing
end

--- @class present.Slides
--- @fields slides present.Slide[]: The slides of the file

---@class present.Slide
---@field title string: The title of the slide
---@field body string[]: The body of the slide

--- Takes some lines and parses them
--- @param lines string[]: The lines in the buffer
--- @return present.Slides

local parse_slides = function(lines)
  local slides = { slides = {} }
  local current_slide = {
    title = '',
    body = {},
  }
  local separator = '^#'
  for _, line in ipairs(lines) do
    if line:find(separator) then
      if #current_slide.title > 0 then
        table.insert(slides.slides, current_slide)
      end

      current_slide = {
        title = line,
        body = {},
      }
    else
      table.insert(current_slide.body, line)
    end
  end

  table.insert(slides.slides, current_slide)

  return slides
end

M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  local parsed = parse_slides(lines)

  ---@type vim.api.keyset.win_config[]
  local width = vim.o.columns
  local height = vim.o.lines

  local windows = {
    background = {
      relative = 'editor',
      width = width,
      height = height,
      style = 'minimal',
      col = 0,
      row = 0,
      zindex = 1,
    },
    header = {
      relative = 'editor',
      width = width,
      height = 1,
      style = 'minimal',
      border = 'rounded',
      col = 0,
      row = 0,
      zindex = 2,
    },
    body = {
      relative = 'editor',
      width = width,
      height = height - 5,
      style = 'minimal',
      border = { ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' },
      col = 1,
      row = 4,
    },
    -- footer = {}
  }

  local background_float = open_floating_window(windows.background)
  local header_float = open_floating_window(windows.header)
  local body_float = open_floating_window(windows.body)

  vim.bo[header_float.buf].filetype = 'markdown'
  vim.bo[body_float.buf].filetype = 'markdown'

  local set_slide_content = function(idx)
    local slide = parsed.slides[idx]

    local padding = string.rep(' ', (width - #slide.title) / 2)
    local title = padding .. slide.title

    vim.api.nvim_buf_set_lines(header_float.buf, 0, -1, false, { title })
    vim.api.nvim_buf_set_lines(body_float.buf, 0, -1, false, slide.body)
  end

  local current_slide = 1
  vim.keymap.set('n', 'n', function()
    current_slide = math.min(current_slide + 1, #parsed.slides)
    set_slide_content(current_slide)
  end, {
    buffer = body_float.buf,
  })

  vim.keymap.set('n', 'p', function()
    current_slide = math.max(current_slide - 1, 1)
    set_slide_content(current_slide)
  end, {
    buffer = body_float.buf,
  })

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(body_float.win, true)
  end, {
    buffer = body_float.buf,
  })

  -- Store options we want toggle off and on
  local restore = {
    cmdheight = {
      original = vim.o.cmdheight,
      present = 0,
    },
  }

  -- Set the options we want during presentation
  for option, config in pairs(restore) do
    vim.opt[option] = config.present
  end

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = body_float.buf,
    callback = function()
      -- Reset values when done with presentation
      for option, config in pairs(restore) do
        vim.opt[option] = config.original
      end
      -- close header too
      pcall(vim.api.nvim_win_close, header_float.win, true)
      pcall(vim.api.nvim_win_close, background_float.win, true)
    end,
  })

  set_slide_content(current_slide)
end

M.start_presentation { bufnr = 57 }

-- vim.print(parse_slides {
--   '# Hello',
--   'Another thing too',
--   '# World',
--   'even more to see here',
-- })
--also nothing
return M
