return function()
  local builtin = require 'telescope.builtin'

  vim.keymap.set('n', 'gh', '0', { desc = 'Go to Line Start' })
  vim.keymap.set('n', 'gl', '$', { desc = 'Go to Line End' })
  vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })
  vim.keymap.set('n', 'H', '<cmd>bprevious<CR>', { desc = 'Previous Buffer' })
  vim.keymap.set('n', 'L', '<cmd>bnext<CR>', { desc = 'Next Buffer' })

  -- vim.keymap.set('n', '<leader>z', function()
  --   if vim.fn.executable 'zoxide' ~= 1 then
  --     builtin.find_files { prompt_title = 'Change Directory' }
  --     return
  --   end
  --
  --   local dirs = vim.fn.systemlist { 'zoxide', 'query', '-l' }
  --   if vim.tbl_isempty(dirs) then
  --     vim.notify('zoxide has no directory history yet', vim.log.levels.INFO)
  --     return
  --   end
  --
  --   vim.ui.select(dirs, { prompt = 'Change Directory' }, function(choice)
  --     if choice and choice ~= '' then vim.cmd.cd(vim.fn.fnameescape(choice)) end
  --   end)
  -- end, { desc = 'Change Directory' })

  -- Toggle a snacks terminal popup
  vim.keymap.set('n', '<leader>t', function() Snacks.terminal.toggle() end, { desc = 'Toggle Terminal' })

  local snacks_popup_opts = {
    auto_close = false,
    win = {
      position = 'bottom',
    },
  }

  vim.keymap.set('n', '<leader>rr', function() Snacks.terminal.toggle('just run', snacks_popup_opts) end, { desc = 'Just Run' })
  vim.keymap.set('n', '<leader>rb', function() Snacks.terminal.toggle('just build', snacks_popup_opts) end, { desc = 'Just Build' })
  vim.keymap.set('n', '<leader>rt', function() Snacks.terminal.toggle('just test', snacks_popup_opts) end, { desc = 'Just Test' })
  vim.keymap.set('n', '<leader>rl', function() Snacks.terminal.toggle('just lint', snacks_popup_opts) end, { desc = 'Just Lint' })
  vim.keymap.set('n', '<leader>rc', function() Snacks.terminal.toggle('just check-all', snacks_popup_opts) end, { desc = 'Just Check-All' })

  pcall(function()
    require('which-key').add {
      -- { '<leader>z', desc = 'Change Directory' },
      { '<leader>x', group = 'Diagnostics' },
      { '<leader>b', group = 'Buffer' },
      { '<leader>t', desc = 'Toggle Terminal Popup' },
      { '<leader>r', group = 'Just Commands' },
      { '<leader>rr', desc = 'Just Run' },
      { '<leader>rb', desc = 'Just Build' },
      { '<leader>rt', desc = 'Just Test' },
      { '<leader>rl', desc = 'Just Lint' },
      { '<leader>rc', desc = 'Just Check-All' },
      { '<leader>o', group = 'Org' },
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
      { '<leader><Tab>s', desc = 'Save Workspace' },
      { '<leader><Tab>d', desc = 'Close Workspace' },
      { '<leader><Tab>D', desc = 'Delete Saved Workspace' },
      { 'gh', desc = 'Go to Line Start' },
      { 'gl', desc = 'Go to Line End' },
      { 'U', desc = 'Redo' },
      { 'H', desc = 'Previous Buffer' },
      { 'L', desc = 'Next Buffer' },
      { '<leader><leader>', desc = 'Find files' },
    }
  end)
end
