return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = function() return vim.fn.executable 'make' == 1 end },
    },
    config = function()
      local telescope = require 'telescope'
      telescope.setup { extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown() } } }
      pcall(telescope.load_extension, 'fzf')
      pcall(telescope.load_extension, 'ui-select')
      local builtin = require 'telescope.builtin'
      for _, map in ipairs {
        { '<leader>ss', builtin.builtin, 'Telescope' },
        { '<leader>sw', builtin.grep_string, 'Current Word' },
        { '<leader>sp', builtin.live_grep, 'Project' },
        { '<leader>sd', builtin.diagnostics, 'Diagnostics' },
        { '<leader>sr', builtin.resume, 'Repeat Last Search' },
        { '<leader>sb', builtin.current_buffer_fuzzy_find, 'Buffer' },
        { '<leader>st', '<cmd>TodoTelescope<CR>', 'Todo' },
        { '<leader><leader>', builtin.find_files, '[ ] Find files' },
      } do
        vim.keymap.set('n', map[1], map[2], { desc = map[3] })
      end
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          for _, map in ipairs {
            { 'grr', builtin.lsp_references, '[G]oto [R]eferences' },
            { 'gri', builtin.lsp_implementations, '[G]oto [I]mplementation' },
            { 'grd', builtin.lsp_definitions, '[G]oto [D]efinition' },
            { 'gO', builtin.lsp_document_symbols, 'Open Document Symbols' },
            { 'gW', builtin.lsp_dynamic_workspace_symbols, 'Open Workspace Symbols' },
            { 'grt', builtin.lsp_type_definitions, '[G]oto [T]ype Definition' },
          } do
            vim.keymap.set('n', map[1], map[2], { buffer = buf, desc = map[3] })
          end
        end,
      })
    end,
  },
}
