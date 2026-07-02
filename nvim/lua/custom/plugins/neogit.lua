vim.pack.add {
  { src = 'https://github.com/nvim-lua/plenary.nvim', version = 'master' },
  { src = 'https://github.com/sindrets/diffview.nvim', version = 'main' },
}

-- Use the local development copy of neogit instead of the upstream repo
vim.opt.runtimepath:prepend(vim.fn.expand '~/dev/neogit')
vim.cmd 'runtime plugin/neogit.lua'

local neogit = require 'neogit'

neogit.setup {
  integrations = {
    diffview = true,
  },
}

vim.keymap.set('n', '<leader>g', function() neogit.open() end, { desc = 'Git' })

pcall(function()
  require('which-key').add {
    { '<leader>g', desc = 'Git' },
  }
end)
