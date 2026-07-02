vim.pack.add {
  { src = 'https://github.com/nvim-lua/plenary.nvim', version = 'master' },
  { src = 'https://github.com/sindrets/diffview.nvim', version = 'main' },
  { src = 'https://github.com/memohnsen/anvil.nvim' },
}

-- To develop against the local checkout instead of the GitHub repo, comment out
-- the anvil entry above and uncomment these two lines:
-- vim.opt.runtimepath:prepend(vim.fn.expand '~/dev/anvil.nvim')
-- vim.cmd 'runtime plugin/anvil.lua'

local anvil = require 'anvil'

anvil.setup {
  integrations = {
    diffview = true,
  },
}

vim.keymap.set('n', '<leader>g', function() anvil.open() end, { desc = 'Git' })

pcall(function()
  require('which-key').add {
    { '<leader>g', desc = 'Git' },
  }
end)
