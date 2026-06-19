vim.pack.add {
  { src = 'https://github.com/windwp/nvim-autopairs', branch = 'master' },
}

require('nvim-autopairs').setup {
  check_ts = true,
  disable_filetype = { 'TelescopePrompt', 'snacks_picker_input' },
  fast_wrap = {},
  map_cr = false,
}
