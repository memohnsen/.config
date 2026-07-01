-- ============================================================
-- SECTION 1: FOUNDATION
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '
  vim.g.have_nerd_font = true
  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.mouse = 'a'
  vim.o.showmode = false

  -- Sync clipboard between OS and Neovim.
  --  Schedule the setting after `UiEnter` because it can increase startup-time.
  --  Remove this option if you want your OS clipboard to remain independent.
  --  See `:help 'clipboard'`
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  vim.o.breakindent = true
  vim.o.undofile = true
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.signcolumn = 'yes'
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300
  vim.o.splitright = true
  vim.o.splitbelow = true
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
  vim.o.inccommand = 'split'
  vim.o.cursorline = true
  vim.o.scrolloff = 20
  vim.o.confirm = true
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    virtual_text = { current_line = false }, -- Text shows up at the end of other lines
    virtual_lines = false, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  local diagnostic_float_augroup = vim.api.nvim_create_augroup('kickstart-diagnostic-float', { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    group = diagnostic_float_augroup,
    callback = function()
      vim.diagnostic.open_float {
        scope = 'cursor',
        focus = false,
      }
    end,
  })

  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ============================================================
-- SECTION 2: PLUGIN MANAGER INTRO
-- vim.pack intro, build hooks
-- ============================================================
do
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 3: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
-- ============================================================
do
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  if vim.g.have_nerd_font then vim.pack.add { gh 'nvim-tree/nvim-web-devicons' } end

  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }

  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    delay = function() return vim.g.which_key_leader_popup == false and 999999 or 0 end,
    icons = { mappings = vim.g.have_nerd_font },
    win = {
      no_overlap = false,
      width = { min = 32, max = 44 },
      height = { min = 4, max = 18 },
      col = -1,
      row = -2,
      border = 'rounded',
      padding = { 1, 2 },
    },
    layout = {
      width = { min = 28, max = 40 },
      spacing = 1,
    },
    spec = {
      { '<leader>s', group = 'Search', mode = { 'n', 'v' } },
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  }

  -- [[ Colorscheme ]]
  vim.pack.add { gh 'navarasu/onedark.nvim' }
  require('onedark').setup {
    style = 'dark',
    code_style = {
      comments = 'none',
    },
  }
  vim.cmd.colorscheme 'onedark'

  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require('mini.ai').setup {
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }
end

-- ============================================================
-- SECTION 4: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================
do
  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

  -- NOTE: You can install multiple plugins at once
  vim.pack.add(telescope_plugins)

  ---@type any
  local telescope = require 'telescope'
  telescope.setup {
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  pcall(telescope.load_extension, 'fzf')
  pcall(telescope.load_extension, 'ui-select')

  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Keymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Files' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = 'Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = 'Current Word' })
  vim.keymap.set('n', '<leader>sp', builtin.live_grep, { desc = 'Project' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Diagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = 'Resume' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = 'Commands' })
  vim.keymap.set('n', '<leader>sb', builtin.current_buffer_fuzzy_find, { desc = 'Buffer' })
  vim.keymap.set('n', '<leader><leader>', builtin.find_files, { desc = '[ ] Find files' })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf

      -- Find references for the word under your cursor.
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

      -- Jump to the implementation of the word under your cursor.
      -- Useful when your language has ways of declaring types without an actual implementation.
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

      -- Jump to the definition of the word under your cursor.
      -- This is where a variable was first declared, or where a function is defined, etc.
      -- To jump back, press <C-t>.
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

      -- Fuzzy find all the symbols in your current document.
      -- Symbols are things like variables, functions, types, etc.
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

      -- Fuzzy find all the symbols in your current workspace.
      -- Similar to document symbols, except searches over your entire project.
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

      -- Jump to the type of the word under your cursor.
      -- Useful when you're not sure what type a variable is and you want to see
      -- the definition of its *type*, not where it was *defined*.
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })
end

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      local peek_definition = function()
        local params = vim.lsp.util.make_position_params(0, 'utf-16')

        vim.lsp.buf_request_all(event.buf, 'textDocument/definition', params, function(responses)
          for _, response in pairs(responses) do
            local result = response.result
            if result and not vim.tbl_isempty(result) then
              local location = result[1] or result

              vim.lsp.util.preview_location(location, {
                border = 'rounded',
                focusable = true,
                max_height = 24,
                max_width = 100,
              })
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

              local uri = location.uri or location.targetUri
              local current_uri = vim.uri_from_bufnr(event.buf)
              local same_file = uri == current_uri

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

      -- Preview the definition of the symbol under your cursor in a popup.
      map('gk', peek_definition, 'Pee[k] Definition')

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      -- if client and client:supports_method('textDocument/inlayHint', event.buf) then
      --   map('<leader>th', function()
      --     local enabled = not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }
      --     vim.b[event.buf].kickstart_inlay_hints_enabled = enabled
      --     vim.lsp.inlay_hint.enable(enabled, { bufnr = event.buf })
      --   end, '[T]oggle Inlay [H]ints')
      --
      --   if client.name == 'rust-analyzer' then
      --     -- Neovim 0.12.1 can render stale Rust inlay-hint columns after edits,
      --     -- which raises "Invalid 'col': out of range" from the decoration provider.
      --     -- Keep Rust hints opt-in until the upstream renderer is fixed.
      --     vim.b[event.buf].kickstart_inlay_hints_enabled = false
      --     vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
      --   end
      -- end
    end,
  })

  ---@type table<string, vim.lsp.Config>

  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  local completion_capabilities = require('blink.cmp').get_lsp_capabilities()

  local servers = {
    postgres_lsp = {},

    stylua = {},

    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  vim.cmd.packadd 'mason.nvim'
  vim.cmd.packadd 'mason-lspconfig.nvim'
  vim.cmd.packadd 'mason-tool-installer.nvim'

  require('mason').setup {}

  local lsp_servers = vim.tbl_keys(servers)

  require('mason-lspconfig').setup {
    ensure_installed = lsp_servers,
  }

  local mason_tools = {
    'debugpy',
    'rust-analyzer',
    'codelldb',
    'taplo',
    'prettier',
    'sqlfluff',
  }

  require('mason-tool-installer').setup {
    ensure_installed = mason_tools,
    integrations = {
      ['mason-lspconfig'] = false,
    },
  }

  for name, server in pairs(servers) do
    server.capabilities = vim.tbl_deep_extend('force', {}, completion_capabilities, server.capabilities or {})
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 6: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
do
  -- [[ Formatting ]]
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = 'fallback',
    },
    default_format_opts = {
      lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    formatters_by_ft = {
      javascript = { 'prettier', stop_after_first = true },
      javascriptreact = { 'prettier', stop_after_first = true },
      typescript = { 'prettier', stop_after_first = true },
      typescriptreact = { 'prettier', stop_after_first = true },
      json = { 'prettier' },
      jsonc = { 'prettier' },
      rust = { 'rustfmt' },
      sql = { 'sqlfluff' },
    },
  }
end

-- ============================================================
-- SECTION 7: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- [[ Autocomplete Engine ]]
  require('blink.cmp').setup {
    keymap = {
      preset = 'enter',
      ['<CR>'] = { 'select_and_accept', 'fallback' },
      ['<C-y>'] = { 'select_and_accept' },
      ['<Tab>'] = {
        function(cmp)
          if cmp.is_menu_visible() then return cmp.select_next() end

          if cmp.snippet_active { direction = 1 } then return cmp.snippet_forward() end

          local ls = require 'luasnip'
          if ls.expandable() then
            ls.expand()
            return true
          end

          return false
        end,
        'fallback',
      },
      ['<S-Tab>'] = {
        function(cmp)
          if cmp.is_menu_visible() then return cmp.select_prev() end

          if cmp.snippet_active { direction = -1 } then return cmp.snippet_backward() end

          return false
        end,
        'fallback',
      },
    },
    snippets = {
      preset = 'luasnip',
    },
    appearance = {
      nerd_font_variant = 'mono',
    },
    completion = {
      accept = {
        auto_brackets = {
          enabled = true,
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
      },
      list = {
        selection = {
          preselect = true,
          auto_insert = false,
        },
      },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    cmdline = {
      enabled = true,
      keymap = {
        preset = 'cmdline',
        ['<Right>'] = false,
        ['<Left>'] = false,
      },
      completion = {
        list = { selection = { preselect = false } },
        menu = {
          auto_show = function() return vim.fn.getcmdtype() == ':' end,
        },
        ghost_text = { enabled = true },
      },
    },
  }

  local accept_completion_or = function(fallback)
    return function()
      local cmp = require 'blink.cmp'
      if cmp.is_visible() or cmp.is_active() then
        cmp.select_and_accept()
        return ''
      end

      if type(fallback) == 'function' then return fallback() end

      return fallback
    end
  end

  local pair_break_cr = function()
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local before = line:sub(col, col)
    local after = line:sub(col + 1, col + 1)
    local pairs = {
      ['('] = ')',
      ['['] = ']',
      ['{'] = '}',
      ['"'] = '"',
      ["'"] = "'",
    }

    if pairs[before] == after then
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local base_indent = line:match '^%s*' or ''
      local shiftwidth = tonumber(vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or vim.bo.tabstop) or 2
      local inner_indent = base_indent .. string.rep(' ', shiftwidth)
      local open_line = line:sub(1, col)
      local close_line = base_indent .. line:sub(col + 1)

      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(0) then return end

        vim.api.nvim_set_current_line(open_line)
        vim.api.nvim_buf_set_lines(0, row, row, false, { inner_indent, close_line })
        vim.api.nvim_win_set_cursor(0, { row + 1, #inner_indent })
      end)

      return ''
    end

    return '\r'
  end

  local tab_completion = function()
    local cmp = require 'blink.cmp'
    if cmp.is_visible() then
      cmp.select_next()
      return ''
    end

    if cmp.snippet_active { direction = 1 } then
      cmp.snippet_forward()
      return ''
    end

    return '\t'
  end

  local shift_tab_completion = function()
    local cmp = require 'blink.cmp'
    if cmp.is_visible() then
      cmp.select_prev()
      return ''
    end

    if cmp.snippet_active { direction = -1 } then
      cmp.snippet_backward()
      return ''
    end

    return vim.api.nvim_replace_termcodes('<S-Tab>', true, false, true)
  end

  local function apply_completion_keymaps(bufnr)
    if vim.bo[bufnr].buftype ~= '' then return end

    local opts = { buffer = bufnr, expr = true, silent = true, replace_keycodes = true }

    vim.keymap.set('i', '<CR>', accept_completion_or(pair_break_cr), opts)
    vim.keymap.set('i', '<Tab>', tab_completion, opts)
    vim.keymap.set('i', '<S-Tab>', shift_tab_completion, opts)
  end

  vim.api.nvim_create_autocmd('InsertEnter', {
    callback = function(args) apply_completion_keymaps(args.buf) end,
  })
end

-- ============================================================
-- SECTION 8: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  local parsers = {
    'bash',
    'c',
    'diff',
    'html',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'query',
    'vim',
    'vimdoc',
    'python',
    'toml',
    'javascript',
    'jsdoc',
    'json',
    'json5',
    'jsonc',
    'tsx',
    'typescript',
    'sql',
    'rust',
  }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    if not vim.treesitter.language.add(language) then return end
    vim.treesitter.start(buf, language)

    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 9: OPTIONAL EXAMPLES / NEXT STEPS
-- kickstart.plugins.* examples
-- ============================================================
do
  require 'custom.plugins'
end
