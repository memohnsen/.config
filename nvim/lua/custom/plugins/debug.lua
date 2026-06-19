local gh = function(repo)
  return 'https://github.com/' .. repo
end

vim.pack.add {
  gh 'mfussenegger/nvim-dap',
  gh 'rcarriga/nvim-dap-ui',
  gh 'nvim-neotest/nvim-nio',
}

local dap = require 'dap'
local dapui = require 'dapui'

dapui.setup()

dap.listeners.after.event_initialized['dapui_config'] = dapui.open
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close

vim.keymap.set('n', '<leader>rdd', function()
  local ok, err = pcall(vim.cmd.RustLsp, 'debuggables')
  if not ok then
    vim.notify('Rust debugger is only available in a Rust project: ' .. err, vim.log.levels.ERROR)
  end
end, { desc = 'Rust Debuggables' })

vim.keymap.set('n', '<leader>rdb', function()
  dap.toggle_breakpoint()
end, { desc = 'Rust Debug: Toggle Breakpoint' })

vim.keymap.set('n', '<leader>rdc', function()
  dap.continue()
end, { desc = 'Rust Debug: Continue' })

vim.keymap.set('n', '<leader>rdu', function()
  dapui.toggle()
end, { desc = 'Rust Debug: Toggle UI' })

pcall(function()
  require('which-key').add {
    { '<leader>rd', group = 'Rust Debug' },
    { '<leader>rdd', desc = 'Rust Debuggables' },
    { '<leader>rdb', desc = 'Rust Debug: Toggle Breakpoint' },
    { '<leader>rdc', desc = 'Rust Debug: Continue' },
    { '<leader>rdu', desc = 'Rust Debug: Toggle UI' },
  }
end)
