vim.pack.add { { src = 'https://git.sr.ht/~swaits/thethethe.nvim', branch = 'main' } }

require('thethethe').setup {
  delay_ms = 1000,
}

vim.defer_fn(function()
  require('config.autocorrect').setup()
end, 1000)
