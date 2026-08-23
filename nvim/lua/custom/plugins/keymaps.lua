return function()
  vim.keymap.set('n', 'gh', '_', { desc = 'Go to Line Start' })
  vim.keymap.set('n', 'gl', '$', { desc = 'Go to Line End' })
  vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })
  vim.keymap.set('n', 'H', '<cmd>bprevious<CR>', { desc = 'Previous Buffer' })
  vim.keymap.set('n', 'L', '<cmd>bnext<CR>', { desc = 'Next Buffer' })

  local reading_gutter_ratio = 0.30
  local reading_gutters = {}

  local function resize_reading_gutter(entry)
    if not vim.api.nvim_win_is_valid(entry.target) or not vim.api.nvim_win_is_valid(entry.spacer) then return end

    local total_width = vim.api.nvim_win_get_width(entry.target) + vim.api.nvim_win_get_width(entry.spacer) + 1
    local gutter_width = math.max(1, math.floor(total_width * reading_gutter_ratio))
    if vim.api.nvim_win_get_width(entry.spacer) ~= gutter_width then vim.api.nvim_win_set_width(entry.spacer, gutter_width) end
  end

  local function close_reading_gutter(target, notify)
    local entry = reading_gutters[target]
    if not entry then return end

    reading_gutters[target] = nil
    if vim.api.nvim_win_is_valid(entry.spacer) then vim.api.nvim_win_close(entry.spacer, true) end
    if vim.api.nvim_win_is_valid(target) then vim.api.nvim_set_current_win(target) end
    if notify then vim.notify 'Left reading gutter disabled' end
  end

  local function toggle_reading_gutter()
    local target = vim.api.nvim_get_current_win()
    if reading_gutters[target] then
      close_reading_gutter(target, true)
      return
    end

    local initial_width = vim.api.nvim_win_get_width(target)
    local gutter_width = math.max(1, math.floor(initial_width * reading_gutter_ratio))
    vim.cmd(('leftabove %dvnew'):format(gutter_width))

    local spacer = vim.api.nvim_get_current_win()
    local buffer = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(buffer, ('reading-gutter://%d'):format(spacer))
    vim.bo[buffer].buftype = 'nofile'
    vim.bo[buffer].bufhidden = 'wipe'
    vim.bo[buffer].buflisted = false
    vim.bo[buffer].swapfile = false
    vim.bo[buffer].modifiable = false
    vim.wo[spacer].number = false
    vim.wo[spacer].relativenumber = false
    vim.wo[spacer].signcolumn = 'no'
    vim.wo[spacer].foldcolumn = '0'
    vim.wo[spacer].statuscolumn = ''
    vim.wo[spacer].winbar = ''
    vim.wo[spacer].list = false
    vim.wo[spacer].cursorline = false
    vim.wo[spacer].winfixwidth = true
    vim.wo[spacer].winhl = 'Normal:Normal,NormalNC:Normal,EndOfBuffer:Normal,WinSeparator:Normal'

    reading_gutters[target] = { target = target, spacer = spacer }
    resize_reading_gutter(reading_gutters[target])
    vim.api.nvim_set_current_win(target)
    vim.notify 'Left reading gutter: 30%'
  end

  local reading_gutter_group = vim.api.nvim_create_augroup('reading-gutter', { clear = true })
  vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = reading_gutter_group,
    callback = function()
      for target, entry in pairs(reading_gutters) do
        if vim.api.nvim_win_is_valid(target) and vim.api.nvim_win_is_valid(entry.spacer) then
          resize_reading_gutter(entry)
        else
          reading_gutters[target] = nil
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd('WinEnter', {
    group = reading_gutter_group,
    callback = function()
      local current = vim.api.nvim_get_current_win()
      for _, entry in pairs(reading_gutters) do
        if current == entry.spacer and vim.api.nvim_win_is_valid(entry.target) then
          vim.schedule(function()
            if vim.api.nvim_win_is_valid(entry.target) then vim.api.nvim_set_current_win(entry.target) end
          end)
          return
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = reading_gutter_group,
    callback = function(args)
      local closed = tonumber(args.match)
      for target, entry in pairs(reading_gutters) do
        if closed == entry.spacer then
          reading_gutters[target] = nil
        elseif closed == target then
          reading_gutters[target] = nil
          vim.schedule(function()
            if vim.api.nvim_win_is_valid(entry.spacer) then vim.api.nvim_win_close(entry.spacer, true) end
          end)
        end
      end
    end,
  })

  vim.keymap.set('n', '<leader>z', toggle_reading_gutter, { desc = 'Toggle Left Reading Gutter' })

  -- Toggle a snacks terminal popup
  vim.keymap.set('n', '<leader>t', function() Snacks.terminal.toggle() end, { desc = 'Toggle Terminal' })
  vim.api.nvim_create_user_command('Bdelete', function(opts) Snacks.bufdelete { force = opts.bang } end, { bang = true })
  vim.cmd [[cnoreabbrev <expr> bd (getcmdtype() == ':' && getcmdline() == 'bd') ? 'Bdelete' : 'bd']]

  pcall(function()
    require('which-key').add {
      { '<leader>z', desc = 'Toggle Left Reading Gutter' },
      { '<leader>x', group = 'Diagnostics' },
      { '<leader>b', group = 'Bookmarks' },
      { '<leader>bm', desc = 'Set Bookmark' },
      { '<leader>bM', desc = 'Delete Bookmark' },
      { '<leader>t', desc = 'Toggle Terminal Popup' },
      { '<leader>j', group = 'Mise Tasks' },
      { '<leader>o', group = 'Org' },
      { '<leader>c', group = 'AI' },
      { '<leader>cc', group = 'Codex' },
      { '<leader>co', desc = 'Opencode Toggle' },
      { '<leader>cu', desc = 'Toggle Cursor Agent' },
      { '<leader>od', desc = 'Daily Note' },
      { '<leader>of', desc = 'Find Org Note' },
      { '<leader>og', desc = 'Grep Org Notes' },
      { '<leader>oa', desc = 'Org Super Agenda' },
      { '<leader>oc', desc = 'Org Capture' },
      { '<leader><Tab>', group = 'Workspace' },
      { '<leader><Tab><Tab>', desc = 'Next Workspace' },
      { '<leader><Tab>l', desc = 'Load Workspace' },
      { '<leader><Tab>1', desc = 'Workspace 1' },
      { '<leader><Tab>2', desc = 'Workspace 2' },
      { '<leader><Tab>3', desc = 'Workspace 3' },
      { '<leader><Tab>4', desc = 'Workspace 4' },
      { '<leader><Tab>n', desc = 'New Workspace' },
      { '<leader><Tab>d', desc = 'Close Workspace' },
      { '<leader><Tab>D', desc = 'Delete Saved Workspace' },
      { 'gh', desc = 'Go to Line Start' },
      { 'gl', desc = 'Go to Line End' },
      { 'U', desc = 'Redo' },
      { 'H', desc = 'Previous Buffer' },
      { 'L', desc = 'Next Buffer' },
      { '<leader><leader>', desc = 'Find files' },
      { '<leader><CR>', desc = 'Jump to Bookmark' },
    }
  end)
end
