return {
  {
    'stevearc/conform.nvim',
    config = function()
      require('conform').setup {
        notify_on_error = false,
        format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
        default_format_opts = { lsp_format = 'fallback' },
        formatters_by_ft = {
          javascript = { 'prettier', stop_after_first = true }, javascriptreact = { 'prettier', stop_after_first = true },
          typescript = { 'prettier', stop_after_first = true }, typescriptreact = { 'prettier', stop_after_first = true },
          json = { 'prettier' }, jsonc = { 'prettier' }, rust = { 'rustfmt' }, sql = { 'sqlfluff' },
        },
      }
    end,
  },
}
