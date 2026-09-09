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
      require('onedark').setup {
        style = 'dark',
        code_style = { comments = 'none' },
        colors = {
          black = '#000000',
          bg0 = '#000000',
          bg1 = '#0d1117',
          bg2 = '#161b22',
          bg3 = '#21262d',
          bg_d = '#050505',
          bg_blue = '#5aa9ff',
          bg_yellow = '#ffd866',
          fg = '#d8dee9',
          grey = '#6b7280',
          light_grey = '#9ca3af',
          red = '#ff5f6d',
          orange = '#ff9f43',
          yellow = '#ffd866',
          green = '#98e06c',
          cyan = '#56d4dd',
          blue = '#5aa9ff',
          purple = '#d787ff',
        },
        highlights = { LspInlayHint = { fg = '#6b7280' } },
      }
      vim.cmd.colorscheme 'onedark'

      local function apply_popup_palette()
        local set = vim.api.nvim_set_hl

        -- LSP hover, signature, definition preview, and diagnostic floats.
        set(0, 'NormalFloat', { fg = '#d8dee9', bg = '#000000' })
        set(0, 'FloatBorder', { fg = '#5aa9ff', bg = '#000000' })

        -- Which-Key
        set(0, 'WhichKeyNormal', { fg = '#d8dee9', bg = '#000000' })
        set(0, 'WhichKeyBorder', { fg = '#5aa9ff', bg = '#000000' })
        set(0, 'WhichKeyTitle', { fg = '#000000', bg = '#5aa9ff', bold = true })
        set(0, 'WhichKey', { fg = '#ffd866', bold = true })
        set(0, 'WhichKeyGroup', { fg = '#d787ff', bold = true })
        set(0, 'WhichKeyDesc', { fg = '#5aa9ff' })
        set(0, 'WhichKeySeparator', { fg = '#6b7280' })
        set(0, 'WhichKeyValue', { fg = '#98e06c' })

        -- Native and Blink completion menus, including command-line results.
        set(0, 'Pmenu', { fg = '#d8dee9', bg = '#000000' })
        set(0, 'PmenuSel', { fg = '#000000', bg = '#5aa9ff', bold = true })
        set(0, 'PmenuSbar', { bg = '#000000' })
        set(0, 'PmenuThumb', { bg = '#6b7280' })
        set(0, 'WildMenu', { fg = '#000000', bg = '#5aa9ff', bold = true })
        set(0, 'BlinkCmpMenu', { fg = '#d8dee9', bg = '#000000' })
        set(0, 'BlinkCmpMenuBorder', { fg = '#5aa9ff', bg = '#000000' })
        set(0, 'BlinkCmpMenuSelection', { fg = '#000000', bg = '#5aa9ff', bold = true })
        set(0, 'BlinkCmpLabel', { fg = '#d8dee9', bg = '#000000' })
        set(0, 'BlinkCmpLabelMatch', { fg = '#ffd866', bg = '#000000', bold = true })
        set(0, 'BlinkCmpLabelDeprecated', { fg = '#6b7280', bg = '#000000', strikethrough = true })
        set(0, 'BlinkCmpLabelDetail', { fg = '#9ca3af', bg = '#000000' })
        set(0, 'BlinkCmpLabelDescription', { fg = '#6b7280', bg = '#000000' })
        set(0, 'BlinkCmpDoc', { fg = '#d8dee9', bg = '#000000' })
        set(0, 'BlinkCmpDocBorder', { fg = '#5aa9ff', bg = '#000000' })
        set(0, 'BlinkCmpDocSeparator', { fg = '#161b22', bg = '#000000' })
        set(0, 'BlinkCmpSignatureHelp', { fg = '#d8dee9', bg = '#000000' })
        set(0, 'BlinkCmpSignatureHelpBorder', { fg = '#5aa9ff', bg = '#000000' })
        set(0, 'BlinkCmpGhostText', { fg = '#6b7280', italic = true })

        -- Start page uses the same onedark blue as floats, which-key, and bufferline.
        local colors = require 'onedark.colors'
        set(0, 'SnacksDashboardNormal', { fg = colors.fg, bg = colors.bg0 })
        set(0, 'SnacksDashboardHeader', { fg = colors.blue, bold = true })
        set(0, 'SnacksDashboardTitle', { fg = colors.blue, bold = true })
        set(0, 'SnacksDashboardIcon', { fg = colors.blue })
        set(0, 'SnacksDashboardDesc', { fg = colors.fg })
        set(0, 'SnacksDashboardKey', { fg = colors.yellow, bold = true })
        set(0, 'SnacksDashboardSpecial', { fg = colors.blue })
        set(0, 'SnacksDashboardFooter', { fg = colors.grey })
        set(0, 'SnacksDashboardDir', { fg = colors.grey })
        set(0, 'SnacksDashboardFile', { fg = colors.fg })
      end

      apply_popup_palette()
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'onedark',
        callback = apply_popup_palette,
      })
    end,
  },
  {
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = false,
      keywords = { TODO = { alt = { 'todo', 'unimplemented' } } },
      highlight = { pattern = { [[.*<(KEYWORDS)\s*:]], [[.*<(KEYWORDS)\s*!]] } },
      search = { pattern = [[\b(KEYWORDS)(:|!)]] },
    },
  },
  { 'nvim-mini/mini.nvim', config = function() require('mini.ai').setup { mappings = { around_next = 'aa', inside_next = 'ii' }, n_lines = 500 } end },
}
