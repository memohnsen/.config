-- render-markdown.nvim: improved viewing of Markdown files in Neovim
-- https://github.com/meanderingprogrammer/render-markdown.nvim

local gh = function(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {
  -- Filetypes this plugin will run on.
  file_types = { 'markdown' },
  completions = { lsp = { enabled = true } },
}
