return {
  {
    'nxuv/just.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'j-hui/fidget.nvim' },
    config = function()
      local just = require 'just'
      just.setup {}

      vim.keymap.set('n', '<leader>j', just.run_task_select, { desc = 'Just Commands' })
    end,
  },
}
