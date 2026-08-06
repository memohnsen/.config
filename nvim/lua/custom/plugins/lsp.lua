return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'j-hui/fidget.nvim',
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'saghen/blink.cmp',
    },
    config = function()
      require('fidget').setup {}

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local function map(keys, func, desc, mode) vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc }) end
          local function peek_definition()
            local params = vim.lsp.util.make_position_params(0, 'utf-16')
            vim.lsp.buf_request_all(event.buf, 'textDocument/definition', params, function(responses)
              for _, response in pairs(responses) do
                local result = response.result
                if result and not vim.tbl_isempty(result) then
                  vim.lsp.util.preview_location(result[1] or result, { border = 'rounded', focusable = true, max_height = 24, max_width = 100 })
                  return
                end
              end
              vim.notify('No definition found', vim.log.levels.INFO)
            end)
          end
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gd', function()
            local params = vim.lsp.util.make_position_params(0, 'utf-16')
            vim.lsp.buf_request_all(event.buf, 'textDocument/definition', params, function(responses)
              for client_id, resp in pairs(responses) do
                local result = resp.result
                if result and not vim.tbl_isempty(result) then
                  local location = vim.islist(result) and result[1] or result
                  local client = vim.lsp.get_client_by_id(client_id)
                  local encoding = client and client.offset_encoding or 'utf-16'
                  local same_file = (location.uri or location.targetUri) == vim.uri_from_bufnr(event.buf)
                  vim.schedule(function()
                    if same_file then vim.cmd 'vsplit' end
                    vim.lsp.util.show_document(location, encoding, { focus = true })
                  end)
                  return
                end
              end
              vim.notify('No definition found', vim.log.levels.INFO)
            end)
          end, '[G]oto [D]efinition')
          map('gk', peek_definition, 'Pee[k] Definition')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>h', function()
              local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, 'Toggle Inlay Hints')
          end

          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local group = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, { buffer = event.buf, group = group, callback = vim.lsp.buf.document_highlight })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { buffer = event.buf, group = group, callback = vim.lsp.buf.clear_references })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end
        end,
      })

      local completion_capabilities = require('blink.cmp').get_lsp_capabilities()
      local servers = {
        -- Installed with Homebrew so this stays on OLS stable rather than
        -- Mason's nightly-only package.
        ols = { cmd = { '/opt/homebrew/bin/ols' } },
        postgres_lsp = {},
        stylua = {},
        zls = {
          settings = {
            zls = {
              -- The project's `check` step avoids emitting a binary; keeping
              -- the compiler alive makes diagnostics after edits near-instant.
              build_on_save_args = { 'check', 'test', '-fincremental' },
            },
          },
        },
        lua_ls = {
          on_init = function(client)
            client.server_capabilities.documentFormattingProvider = false
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
            end
            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
              workspace = {
                checkThirdParty = false,
                library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), { '${3rd}/luv/library', '${3rd}/busted/library' }),
              },
            })
          end,
          settings = { Lua = { format = { enable = false } } },
        },
      }

      require('mason').setup {}
      local mason_servers = vim.tbl_filter(function(name) return name ~= 'ols' end, vim.tbl_keys(servers))
      require('mason-lspconfig').setup { ensure_installed = mason_servers, automatic_enable = { exclude = { 'rust_analyzer' } } }
      require('mason-tool-installer').setup {
        ensure_installed = { 'debugpy', 'rust-analyzer', 'codelldb', 'taplo', 'prettier', 'sqlfluff' },
        integrations = { ['mason-lspconfig'] = false },
      }
      for name, server in pairs(servers) do
        server.capabilities = vim.tbl_deep_extend('force', {}, completion_capabilities, server.capabilities or {})
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end

      -- sourcekit-lsp ships with Xcode / the Swift toolchain (not Mason).
      -- https://www.swift.org/documentation/articles/zero-to-swift-nvim.html
      local sourcekit_cmd = { 'sourcekit-lsp' }
      local xcrun = vim.fn.exepath 'xcrun'
      if xcrun ~= '' then
        local result = vim.system({ 'xcrun', '--find', 'sourcekit-lsp' }, { text = true }):wait()
        if result.code == 0 then
          local path = vim.fn.trim(result.stdout)
          if path ~= '' and vim.fn.executable(path) == 1 then sourcekit_cmd = { path } end
        end
      end
      vim.lsp.config('sourcekit', {
        cmd = sourcekit_cmd,
        filetypes = { 'swift' },
        capabilities = vim.tbl_deep_extend('force', {}, completion_capabilities, {
          workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
          textDocument = { diagnostic = { dynamicRegistration = true, relatedDocumentSupport = true } },
        }),
      })
      vim.lsp.enable 'sourcekit'
    end,
  },
}
