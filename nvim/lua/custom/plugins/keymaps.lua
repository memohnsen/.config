local builtin = require 'telescope.builtin'

vim.keymap.set('n', 'gh', '0', { desc = 'Go to Line Start' })
vim.keymap.set('n', 'gl', '$', { desc = 'Go to Line End' })
vim.keymap.set('n', 'ge', 'G', { desc = 'Go to File Bottom' })
vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })
vim.keymap.set('n', 'H', '<cmd>bprevious<CR>', { desc = 'Previous Buffer' })
vim.keymap.set('n', 'L', '<cmd>bnext<CR>', { desc = 'Next Buffer' })
vim.keymap.set('n', '{', '<C-u>', { desc = 'Scroll Up' })
vim.keymap.set('n', '}', '<C-d>', { desc = 'Scroll Down' })

local org_dir = vim.fn.expand '~/dev/org'
local daily_dir = org_dir .. '/daily'

vim.keymap.set('n', '<leader>z', function()
  if vim.fn.executable 'zoxide' ~= 1 then
    builtin.find_files { prompt_title = 'Change Directory' }
    return
  end

  local dirs = vim.fn.systemlist { 'zoxide', 'query', '-l' }
  if vim.tbl_isempty(dirs) then
    vim.notify('zoxide has no directory history yet', vim.log.levels.INFO)
    return
  end

  vim.ui.select(dirs, { prompt = 'Change Directory' }, function(choice)
    if choice and choice ~= '' then vim.cmd.cd(vim.fn.fnameescape(choice)) end
  end)
end, { desc = 'Change Directory' })

vim.keymap.set('n', '<leader>bd', function()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].modified then
    vim.notify('Buffer has unsaved changes', vim.log.levels.WARN)
    return
  end

  local listed = vim.fn.getbufinfo { buflisted = 1 }
  local target

  for index, info in ipairs(listed) do
    if info.bufnr == bufnr then
      for offset = 1, #listed - 1 do
        local candidate = listed[((index + offset - 1) % #listed) + 1].bufnr
        if candidate ~= bufnr then
          target = candidate
          break
        end
      end

      break
    end
  end

  target = target or vim.api.nvim_create_buf(true, false)

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then vim.api.nvim_win_set_buf(win, target) end
  end

  vim.api.nvim_buf_delete(bufnr, {})
end, { desc = 'Delete Buffer' })

vim.keymap.set('n', '<leader>T', function()
  vim.cmd 'enew'
  vim.cmd 'terminal'
  vim.cmd 'startinsert'
end, { desc = 'New Terminal Buffer' })

-- Toggle a snacks terminal popup
vim.keymap.set('n', '<leader>t', function() Snacks.terminal.toggle() end, { desc = 'Toggle Terminal Popup' })

vim.keymap.set('n', '<leader>wd', function()
  if #vim.api.nvim_list_wins() == 1 then
    vim.notify('Cannot delete the last window', vim.log.levels.WARN)
    return
  end

  vim.cmd.close()
end, { desc = 'Delete Window' })

vim.keymap.set('n', '<leader>ww', '<C-w>w', { desc = 'Switch Window' })
vim.keymap.set('n', '<leader>wh', '<C-w>h', { desc = 'Focus Left Window' })
vim.keymap.set('n', '<leader>wj', '<C-w>j', { desc = 'Focus Lower Window' })
vim.keymap.set('n', '<leader>wk', '<C-w>k', { desc = 'Focus Upper Window' })
vim.keymap.set('n', '<leader>wl', '<C-w>l', { desc = 'Focus Right Window' })
vim.keymap.set('n', '<leader>wv', '<cmd>vsplit<CR>', { desc = 'Vertical Split' })
vim.keymap.set('n', '<leader>ws', '<cmd>split<CR>', { desc = 'Horizontal Split' })

local function current_buffer_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name == '' then return vim.fn.getcwd() end

  return vim.fs.dirname(name)
end

local function cargo_root()
  local manifest = vim.fs.find('Cargo.toml', {
    path = current_buffer_dir(),
    upward = true,
  })[1]

  if manifest then return vim.fs.dirname(manifest) end

  return vim.fn.getcwd()
end

local function run_shell(command, cwd)
  vim.cmd 'enew'
  vim.fn.jobstart(command, {
    cwd = cwd,
    term = true,
  })
  vim.cmd 'startinsert'
end

local function cargo_terminal(action) run_shell('cargo ' .. action, cargo_root()) end

vim.keymap.set('n', '<leader>rr', function() cargo_terminal 'run' end, { desc = 'Cargo Run' })
vim.keymap.set('n', '<leader>rb', function() Snacks.terminal.toggle() end, { desc = 'Cargo Build' })
vim.keymap.set('n', '<leader>rt', function() Snacks.terminal.toggle() end, { desc = 'Cargo Test' })
vim.keymap.set('n', '<leader>rc', function() Snacks.terminal.toggle() end, { desc = 'Cargo Clippy' })

local function pick_org_notes()
  builtin.find_files {
    cwd = org_dir,
    find_command = { 'rg', '--files', '--glob', '*.org' },
    prompt_title = 'Org Notes',
  }
end

local function grep_org_notes()
  builtin.live_grep {
    cwd = org_dir,
    glob_pattern = '*.org',
    prompt_title = 'Grep Org Notes',
  }
end

local function open_daily_note()
  vim.fn.mkdir(daily_dir, 'p')

  local file = daily_dir .. '/' .. os.date '%Y-%m-%d' .. '.org'
  local is_new = vim.fn.filereadable(file) == 0

  vim.cmd.edit(vim.fn.fnameescape(file))

  if is_new then
    local title = os.date '%A, %B %e, %Y'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      '#+title: ' .. title,
      '',
      '* What I did',
      '* TODO ',
      '',
      '* Notes',
      '',
    })
  end
end

vim.api.nvim_create_user_command('OrgFiles', pick_org_notes, { desc = 'Pick an org-mode note under ~/dev/org' })

vim.keymap.set('n', '<leader>od', open_daily_note, { desc = 'Daily Note' })
vim.keymap.set('n', '<leader>of', pick_org_notes, { desc = 'Find Org Note' })
vim.keymap.set('n', '<leader>og', grep_org_notes, { desc = 'Grep Org Notes' })

vim.keymap.set('c', '<CR>', function()
  if vim.fn.getcmdtype() == ':' then
    local command = vim.trim(vim.fn.getcmdline())
    if command == '' then return '<cmd>write<CR>' end
    if command:match '^q!?$' or command:match '^quit!?$' or command:match '^qa!?$' or command:match '^qall!?$' then
      if _G.kickstart_org_active_clock_message then
        local message = _G.kickstart_org_active_clock_message()
        if message then
          vim.notify(message, vim.log.levels.ERROR)
          return '<C-c>'
        end
      end
    end
  end

  return '<CR>'
end, { expr = true, desc = 'Write from Empty Cmdline' })

vim.keymap.set('n', 'gte', function()
  vim.diagnostic.jump {
    count = 1,
    severity = vim.diagnostic.severity.ERROR,
  }
end, { desc = 'Next Error' })

vim.keymap.set(
  'n',
  'gtE',
  function()
    vim.diagnostic.jump {
      count = -1,
      severity = vim.diagnostic.severity.ERROR,
    }
  end,
  { desc = 'Previous Error' }
)

pcall(
  function()
    require('which-key').add {
      { '<leader>z', desc = 'Change Directory' },
      { '<leader>g', group = 'Git' },
      { '<leader>x', group = 'Diagnostics' },
      { '<leader>b', group = 'Buffer' },
      { '<leader>bd', desc = 'Delete Buffer' },
      { '<leader>T', desc = 'New Terminal Buffer' },
      { '<leader>t', desc = 'Toggle Terminal Popup' },
      { '<leader>w', group = 'Window' },
      { '<leader>wd', desc = 'Delete Window' },
      { '<leader>ww', desc = 'Switch Window' },
      { '<leader>wh', desc = 'Focus Left Window' },
      { '<leader>wj', desc = 'Focus Lower Window' },
      { '<leader>wk', desc = 'Focus Upper Window' },
      { '<leader>wl', desc = 'Focus Right Window' },
      { '<leader>wv', desc = 'Vertical Split' },
      { '<leader>ws', desc = 'Horizontal Split' },
      { '<leader>r', group = 'Rust Tools' },
      { '<leader>rr', desc = 'Cargo Run' },
      { '<leader>rb', desc = 'Cargo Build' },
      { '<leader>rt', desc = 'Cargo Test' },
      { '<leader>rc', desc = 'Cargo Clippy' },
      { '<leader>o', group = 'Org' },
      { '<leader>od', desc = 'Daily Note' },
      { '<leader>of', desc = 'Find Org Note' },
      { '<leader>og', desc = 'Grep Org Notes' },
      { '<leader>oa', desc = 'Org Super Agenda' },
      { '<leader>oc', desc = 'Org Capture' },
      { '<leader><Tab>', group = 'Workspace' },
      { '<leader><Tab>.', desc = 'Search Sessions' },
      { '<leader><Tab><Tab>', desc = 'Next Workspace' },
      { '<leader><Tab>l', desc = 'Load Workspace' },
      { '<leader><Tab>1', desc = 'Workspace 1' },
      { '<leader><Tab>2', desc = 'Workspace 2' },
      { '<leader><Tab>3', desc = 'Workspace 3' },
      { '<leader><Tab>4', desc = 'Workspace 4' },
      { '<leader><Tab>5', desc = 'Workspace 5' },
      { '<leader><Tab>6', desc = 'Workspace 6' },
      { '<leader><Tab>7', desc = 'Workspace 7' },
      { '<leader><Tab>8', desc = 'Workspace 8' },
      { '<leader><Tab>9', desc = 'Workspace 9' },
      { '<leader><Tab>n', desc = 'New Workspace' },
      { '<leader><Tab>r', desc = 'Rename Workspace' },
      { '<leader><Tab>s', desc = 'Save Workspace' },
      { '<leader><Tab>S', desc = 'Save Workspace As' },
      { '<leader><Tab>d', desc = 'Close Workspace' },
      { '<leader><Tab>D', desc = 'Delete Saved Workspace' },
      { 'gh', desc = 'Go to Line Start' },
      { 'gl', desc = 'Go to Line End' },
      { 'ge', desc = 'Go to File Bottom' },
      { 'U', desc = 'Redo' },
      { 'H', desc = 'Previous Buffer' },
      { 'L', desc = 'Next Buffer' },
      { '{', desc = 'Scroll Up' },
      { '}', desc = 'Scroll Down' },
      { '<D-s>', desc = 'Save File' },
      { 'gte', desc = 'Next Error' },
      { 'gtE', desc = 'Previous Error' },
      { '<leader><leader>', desc = 'Find files' },
    }
  end
)
