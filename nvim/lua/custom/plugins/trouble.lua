vim.pack.add { { src = 'https://github.com/folke/trouble.nvim', branch = 'main' } }

require('trouble').setup {}

vim.keymap.set('n', '<leader>x', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', {
  desc = 'Diagnostics (Current File)',
})
