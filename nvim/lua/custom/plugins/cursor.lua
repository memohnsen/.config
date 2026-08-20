return {
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-treesitter/nvim-treesitter', lazy = true },
      { 'nvim-telescope/telescope.nvim', optional = true },
      { 'MeanderingProgrammer/render-markdown.nvim', optional = true },
      { 'folke/snacks.nvim', optional = true },
      { 'agent-shell', optional = true }, -- For Cursor ACP integration
    },
    cmd = 'CodeCompanion',
    keys = {
      {
        '<leader>cc',
        function() require('codecompanion').chat() end,
        desc = 'Open Chat',
        mode = { 'n', 'i' },
      },
      {
        '<leader>ca',
        function() require('codecompanion').actions.apply_action() end,
        desc = 'Apply Action',
        mode = { 'n', 'i' },
      },
      {
        '<leader>cu',
        function() require('codecompanion').chat() end,
        desc = 'Open Cursor Chat',
        mode = { 'n', 'i' },
      },
      {
        '<leader>ct',
        function() require('codecompanion').commands() end,
        desc = 'Command Palette',
        mode = { 'n' },
      },
    },
    config = function()
      require('codecompanion').setup({
        adapters = {
          cursor = {
            command = { 'cursor', 'acp' },
            args = {},
            schema = 'cursor',
            proxy_adapter = true,
          },
          -- Configure opencode as fallback
          opencode = {
            command = 'opencode',
            args = { 'serve' },
            schema = 'opencode',
            family = 'opencode',
          },
        },
        strategies = {
          chat = {
            adapter = 'cursor',
          },
        },
        opts = {
          auto_accept = true,
          mixins = {
            -- Maybe provide additional options for cursor
            [' modelos'] = {
              force_mix_in_strategies = 'chat',
            },
          },
          logging = false,
        },
        display = {
          action_palette = {
            title = 'Action Palette',
            icon = '💡',
            border = 'rounded',
            height = 0.5,
            width = 0.5,
            preview = false,
          },
          chat = {
            window = {
              layout = 'vertical',
              position = 'right',
              width = 0.45,
              height = 0.75,
            },
            show_flags = true,
            show_tool_name = true,
            show_registers = true,
            show_context = true,
            show_diff = true,
            show_warnings = true,
            show_thoughts = false,
            show_latency = true,
            intro_text = 'Chat with Cursor or other ACP agents',
            border = true,
          },
          action_palette = {
            border = 'rounded',
          },
        },
      })
    end,
  },
}
