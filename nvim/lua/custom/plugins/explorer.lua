return {
  {
    'folke/snacks.nvim',
    config = function()
      local snacks = require 'snacks'
      snacks.setup {
        explorer = { replace_netrw = false },
        terminal = {
          win = {
            keys = {
              close = { '<C-;>', 'hide', mode = 't', desc = 'Close Terminal Popup' },
            },
          },
        },
        image = { enabled = true, doc = { enabled = false, inline = false, float = true, max_width = 80, max_height = 40 } },
        picker = {
          sources = {
            explorer = { hidden = true, ignored = true, jump = { close = true } },
            files = { hidden = true, ignored = true, exclude = { 'target', 'target/**' } },
            grep = { hidden = false, ignored = true, exclude = { 'target', 'target/**' } },
            git_status = { ignored = true },
          },
        },
      }
      local function project_root()
        local git_root = vim.fn.systemlist { 'git', 'rev-parse', '--show-toplevel' }
        return vim.v.shell_error == 0 and git_root[1] and git_root[1] ~= '' and git_root[1] or vim.fn.getcwd()
      end
      vim.keymap.set('n', '<leader>e', function() (snacks.explorer or snacks.picker.explorer) { cwd = project_root() } end, { desc = 'Explorer Root' })
      pcall(function() require('which-key').add { { '<leader>e', desc = 'File Explorer' } } end)
    end,
  },
}
