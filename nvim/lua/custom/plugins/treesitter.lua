return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        parser_install_dir = vim.fn.stdpath 'data' .. '/site',
        ensure_installed = {
          'bash',
          'c',
          'diff',
          'html',
          'json',
          'json5',
          'jsonc',
          'lua',
          'luadoc',
          'markdown',
          'markdown_inline',
          'query',
          'rust',
          'sql',
          'toml',
          'vim',
          'vimdoc',
        },
        highlight = { enable = true },
        indent = { enable = true },
      }
    end,
  },
}
