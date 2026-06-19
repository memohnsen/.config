vim.pack.add {
  { src = 'https://github.com/numToStr/Comment.nvim', branch = 'master' },
}

require('Comment').setup {
  mappings = {
    basic = true,
    extra = true,
  },
}
