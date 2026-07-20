return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ':TSUpdate',
    config = function()
      -- tree-sitter CLI 0.25+ removed --no-bindings; master still passes it for generate-from-grammar langs.
      local install = require 'nvim-treesitter.install'
      install.ts_generate_args = { 'generate', '--abi', tostring(vim.treesitter.language_version) }

      local parser_dir = vim.fn.stdpath 'data' .. '/site'
      vim.opt.runtimepath:prepend(parser_dir)

      require('nvim-treesitter.configs').setup {
        parser_install_dir = parser_dir,
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
          'swift',
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
