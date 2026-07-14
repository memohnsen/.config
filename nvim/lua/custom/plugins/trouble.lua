return {
  {
    'folke/trouble.nvim',
    config = function()
      require('trouble').setup {}
      vim.keymap.set('n', '<leader>d', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Diagnostics (Current File)' })
    end,
  },
}
