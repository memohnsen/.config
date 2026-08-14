return {
  {
    'sudo-tee/opencode.nvim',
    cmd = 'Opencode',
  keys = {
    {
      '<leader>co',
      function() require('opencode.api').toggle() end,
      desc = 'Opencode Toggle',
      mode = { 'n', 't' },
    },
  },
  opts = {
    keymap_prefix = '<leader>co',
    keymap = {
      input_window = {
        ['<cr>'] = { 'submit_input_prompt', mode = { 'n', 'i' }, defer_to_completion = true },
      },
    },
    ui = {
      position = 'right',
      window_width = 0.40,
      icons = { preset = 'nerdfonts' },
    },
  },
  dependencies = {
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        anti_conceal = { enabled = false },
        file_types = { 'markdown', 'opencode_output' },
      },
      ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },
    },
    { 'saghen/blink.cmp', optional = true },
    { 'folke/snacks.nvim', optional = true },
  },
  },
}
