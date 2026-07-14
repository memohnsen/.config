return {
  {
    'memohnsen/anvil.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'sindrets/diffview.nvim' },
    config = function()
      local anvil = require 'anvil'
      anvil.setup { integrations = { diffview = true } }
      vim.keymap.set('n', '<leader>g', anvil.open, { desc = 'Git' })
      pcall(function() require('which-key').add { { '<leader>g', desc = 'Git' } } end)
    end,
  },
}
