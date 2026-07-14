return {
  { 'NMAC427/guess-indent.nvim', config = true },
  { 'nvim-tree/nvim-web-devicons', cond = function() return vim.g.have_nerd_font end },
  {
    'lewis6991/gitsigns.nvim',
    opts = { signs = { add = { text = '+' }, change = { text = '~' }, delete = { text = '_' }, topdelete = { text = '‾' }, changedelete = { text = '~' } } },
  },
  {
    'folke/which-key.nvim',
    opts = {
      delay = function() return vim.g.which_key_leader_popup == false and 999999 or 0 end,
      icons = { mappings = vim.g.have_nerd_font },
      win = { no_overlap = false, width = { min = 32, max = 44 }, height = { min = 4, max = 18 }, col = -1, row = -2, border = 'rounded', padding = { 1, 2 } },
      layout = { width = { min = 28, max = 40 }, spacing = 1 },
      spec = { { '<leader>s', group = 'Search', mode = { 'n', 'v' } }, { 'gr', group = 'LSP Actions', mode = { 'n' } } },
    },
  },
  {
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      require('onedark').setup { style = 'dark', code_style = { comments = 'none' } }
      vim.cmd.colorscheme 'onedark'
    end,
  },
  {
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false, keywords = { TODO = { alt = { 'todo', 'unimplemented' } } }, highlight = { pattern = { [[.*<(KEYWORDS)\s*:]], [[.*<(KEYWORDS)\s*!]] } }, search = { pattern = [[\b(KEYWORDS)(:|!)]] } },
  },
  { 'nvim-mini/mini.nvim', config = function() require('mini.ai').setup { mappings = { around_next = 'aa', inside_next = 'ii' }, n_lines = 500 } end },
}
