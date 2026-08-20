local new_chat_on_next_open = false

local function shutdown_opencode()
  local state = require('opencode.state')
  local ui = require('opencode.ui.ui')

  ui.teardown_visible_windows(state.windows)
  ui.drop_hidden_snapshot()
  state.session.clear_active()

  if state.opencode_server then
    state.opencode_server:shutdown()
  end

  new_chat_on_next_open = true
end

return {
  {
    'sudo-tee/opencode.nvim',
    cmd = 'Opencode',
    keys = {
      {
        '<leader>co',
        function()
          local new_session = new_chat_on_next_open
          new_chat_on_next_open = false
          require('opencode.api').toggle(new_session)
        end,
        desc = 'Opencode Toggle',
        mode = { 'n', 't' },
      },
    },
    config = function(_, opts)
      require('opencode').setup(opts)
    end,
    opts = {
      default_global_keymaps = false,
      keymap = {
        input_window = {
          ['<cr>'] = { 'submit_input_prompt', mode = { 'n', 'i' }, defer_to_completion = true },
          ['<C-c>'] = {
            shutdown_opencode,
            mode = { 'n', 'i' },
            defer_to_completion = true,
          },
        },
        output_window = {
          ['<C-c>'] = {
            shutdown_opencode,
          },
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
