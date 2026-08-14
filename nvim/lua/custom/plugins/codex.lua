return {
  {
    'kkrampis/codex.nvim',
    cmd = { 'Codex', 'CodexToggle' },
    keys = {
      {
        '<leader>c',
        function() require('codex').toggle() end,
        desc = 'Toggle Codex panel',
        mode = { 'n', 't' },
      },
    },
    opts = {
      keymaps = {
        -- Lazy owns the toggle mapping above; only keep the buffer-local quit
        -- mapping here so the same key is not registered twice.
        toggle = nil,
        quit = '<C-q>',
      },
      border = 'rounded',
      width = 0.4,
      height = 1.0,
      autoinstall = false,
      panel = true,
      use_buffer = false,
    },
  },
}
