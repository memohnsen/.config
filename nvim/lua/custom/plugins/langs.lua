local gh = function(repo)
  return 'https://github.com/' .. repo
end

local function organize_rust_imports(bufnr)
  if #vim.lsp.get_clients({ bufnr = bufnr, name = 'rust-analyzer' }) == 0 then
    return
  end
  vim.lsp.buf.code_action({
    bufnr = bufnr,
    apply = true,
    context = {
      diagnostics = {},
      only = { 'source.organizeImports' },
    },
  })
end

vim.g.rustaceanvim = {
  server = {
    on_attach = function(client, bufnr)
      if client.name ~= 'rust-analyzer' then
        return
      end
      local group = vim.api.nvim_create_augroup('RustOrganizeImportsOnSave', { clear = false })
      vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = group,
        buffer = bufnr,
        callback = function(args)
          organize_rust_imports(args.buf)
        end,
      })
    end,
    default_settings = {
      ['rust-analyzer'] = {
        check = {
          command = 'clippy',
        },
      },
    },
  },
}

vim.pack.add { gh 'mrcjkb/rustaceanvim' }
