vim.pack.add {
  { src = 'https://github.com/nvim-lua/plenary.nvim', version = 'master' },
  { src = 'https://github.com/sindrets/diffview.nvim', version = 'main' },
  { src = 'https://github.com/NeogitOrg/neogit', version = 'master' },
}

local neogit = require 'neogit'

neogit.setup {
  integrations = {
    diffview = true,
  },
}

vim.keymap.set('n', '<leader>gg', function()
  neogit.open()
end, { desc = 'Neogit' })

pcall(function()
  require('which-key').add {
    { '<leader>gg', desc = 'Neogit' },
  }
end)
