local builtin = require 'telescope.builtin'

vim.keymap.set('n', 'gh', '0', { desc = 'Go to Line Start' })
vim.keymap.set('n', 'gl', '$', { desc = 'Go to Line End' })
vim.keymap.set('n', 'ge', 'G', { desc = 'Go to File Bottom' })
vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })
vim.keymap.set('n', 'H', '<cmd>bprevious<CR>', { desc = 'Previous Buffer' })
vim.keymap.set('n', 'L', '<cmd>bnext<CR>', { desc = 'Next Buffer' })
vim.keymap.set('n', '{', '<C-u>', { desc = 'Scroll Up' })
vim.keymap.set('n', '}', '<C-d>', { desc = 'Scroll Down' })
vim.keymap.set('n', '<M-j>', '<cmd>move .+1<CR>==', { desc = 'Move Line Down' })
vim.keymap.set('n', '<M-k>', '<cmd>move .-2<CR>==', { desc = 'Move Line Up' })
vim.keymap.set('v', '<M-j>', ":move '>+1<CR>gv=gv", { desc = 'Move Selection Down' })
vim.keymap.set('v', '<M-k>', ":move '<-2<CR>gv=gv", { desc = 'Move Selection Up' })
vim.keymap.set({ 'n', 'i', 'v' }, '<D-s>', '<cmd>write<CR>', { desc = 'Save File' })

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

vim.keymap.set('n', '<leader>bt', function()
  vim.cmd 'enew'
  vim.cmd 'terminal'
  vim.cmd 'startinsert'
end, { desc = 'New Terminal Buffer' })

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

vim.keymap.set('n', '<leader>tw', function()
  vim.g.which_key_leader_popup = vim.g.which_key_leader_popup == false

  if vim.g.which_key_leader_popup == false then pcall(function() require('which-key.view').hide() end) end

  local state = vim.g.which_key_leader_popup == false and 'hidden' or 'shown'
  vim.notify('Which-key leader popup ' .. state, vim.log.levels.INFO)
end, { desc = 'Toggle Which-Key' })

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

local function cargo_terminal(action)
  run_shell('cargo ' .. action, cargo_root())
end

local function cargo_zellij_float(action)
  if vim.env.ZELLIJ == nil or vim.fn.executable 'zellij' ~= 1 then
    cargo_terminal(action)
    return
  end

  local job_id = vim.fn.jobstart({
    'zellij',
    'run',
    '--floating',
    '--cwd',
    cargo_root(),
    '--name',
    'cargo ' .. action,
    '--',
    'cargo',
    action,
  })

  if job_id <= 0 then cargo_terminal(action) end
end

local function strip_leading_comment_marker(line)
  local command = vim.trim(line)

  local markers = {
    '///',
    '//!',
    '--',
    '//',
    '#',
    '"',
    ';',
    '*',
  }

  local commentstring = vim.bo.commentstring
  if commentstring and commentstring ~= '' then
    local prefix = vim.split(commentstring, '%%s', { plain = false, trimempty = true })[1]
    prefix = prefix and vim.trim(prefix)
    if prefix and prefix ~= '' then table.insert(markers, prefix) end
  end

  local changed = true
  while changed do
    changed = false
    command = vim.trim(command)

    for _, marker in ipairs(markers) do
      local stripped, count = command:gsub('^' .. vim.pesc(marker) .. '%s*', '', 1)
      if count > 0 then
        command = stripped
        changed = true
        break
      end
    end
  end

  return command
end

local function run_current_line()
  local command = strip_leading_comment_marker(vim.api.nvim_get_current_line())

  if command == '' then
    vim.notify('No command on current line', vim.log.levels.WARN)
    return
  end

  run_shell(command, current_buffer_dir())
end

vim.keymap.set('n', '<leader>rl', run_current_line, { desc = 'Run Current Line' })

vim.keymap.set('n', '<leader>rr', function() cargo_terminal 'run' end, { desc = 'Cargo Run' })
vim.keymap.set('n', '<leader>rb', function() cargo_zellij_float 'build' end, { desc = 'Cargo Build' })
vim.keymap.set('n', '<leader>rt', function() cargo_zellij_float 'test' end, { desc = 'Cargo Test' })
vim.keymap.set('n', '<leader>rc', function() cargo_zellij_float 'clippy' end, { desc = 'Cargo Clippy' })

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
      { '<leader>bt', desc = 'New Terminal Buffer' },
      { '<leader>w', group = 'Window' },
      { '<leader>t', group = 'Toggle' },
      { '<leader>wd', desc = 'Delete Window' },
      { '<leader>ww', desc = 'Switch Window' },
      { '<leader>wh', desc = 'Focus Left Window' },
      { '<leader>wj', desc = 'Focus Lower Window' },
      { '<leader>wk', desc = 'Focus Upper Window' },
      { '<leader>wl', desc = 'Focus Right Window' },
      { '<leader>wv', desc = 'Vertical Split' },
      { '<leader>ws', desc = 'Horizontal Split' },
      { '<leader>tw', desc = 'Toggle Which-Key' },
      { '<leader>r', group = 'Rust Tools' },
      { '<leader>rr', desc = 'Cargo Run' },
      { '<leader>rb', desc = 'Cargo Build' },
      { '<leader>rt', desc = 'Cargo Test' },
      { '<leader>rc', desc = 'Cargo Clippy' },
      { '<leader>rl', desc = 'Run Current Line' },
      { '<leader>rd', group = 'Rust Debug' },
      { '<leader>rdd', desc = 'Rust Debuggables' },
      { '<leader>rdb', desc = 'Rust Debug: Toggle Breakpoint' },
      { '<leader>rdc', desc = 'Rust Debug: Continue' },
      { '<leader>rdu', desc = 'Rust Debug: Toggle UI' },
      { '<leader>o', group = 'Org' },
      { '<leader>od', desc = 'Daily Note' },
      { '<leader>of', desc = 'Find Org Note' },
      { '<leader>og', desc = 'Grep Org Notes' },
      { '<leader>oa', desc = 'Org Super Agenda' },
      { '<leader>oc', desc = 'Org Capture' },
      { '<leader>oC', desc = 'Sync macOS Calendar' },
      { '<leader>oG', desc = 'Commit and Push Org Dir' },
      { '<leader><Tab>', group = 'Workspace' },
      { '<leader><Tab>.', desc = 'Search Sessions' },
      { '<leader><Tab><Tab>', desc = 'Next Workspace' },
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
      { '<leader><Tab>s', desc = 'Save Workspace As' },
      { '<leader><Tab>d', desc = 'Delete Workspace' },
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
