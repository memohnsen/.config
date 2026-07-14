return {
  {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup { check_ts = true, disable_filetype = { 'TelescopePrompt', 'snacks_picker_input' }, fast_wrap = {}, map_cr = false }
    end,
  },
}
