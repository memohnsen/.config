return {
  {
    'stevearc/conform.nvim',
    config = function()
      -- `zig fmt` uses a trailing comma as the signal that a list should stay
      -- multiline. Add that signal before Conform asks ZLS to format the file.
      local zig_max_inline_parameters = 3

      local function force_zig_multiline_lists(bufnr)
        if vim.bo[bufnr].filetype ~= 'zig' then return end

        local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'zig')
        if not ok or not parser then return end

        local edits = {}
        local container_types = {
          enum_declaration = true,
          struct_declaration = true,
          union_declaration = true,
        }

        local function add_trailing_comma(node)
          local _, _, end_row, end_col = node:range()
          local closing = vim.api.nvim_buf_get_text(bufnr, end_row, end_col - 1, end_row, end_col, {})[1]
          if closing ~= '}' and closing ~= ')' then return end

          local last_named = node:named_child(node:named_child_count() - 1)
          if not last_named then return end
          local _, _, row, col = last_named:range()
          local suffix = table.concat(vim.api.nvim_buf_get_text(bufnr, row, col, end_row, end_col - 1, {}), '\n')
          if not suffix:find(',', 1, true) then table.insert(edits, { row = row, col = col }) end
        end

        local function visit(node)
          if container_types[node:type()] then
            local fields = 0
            for child in node:iter_children() do
              if child:named() and child:type() == 'container_field' then fields = fields + 1 end
            end
            if fields > 1 then add_trailing_comma(node) end
          elseif node:type() == 'parameters' then
            local parameters = 0
            for child in node:iter_children() do
              if child:named() and child:type() == 'parameter' then parameters = parameters + 1 end
            end
            if parameters > zig_max_inline_parameters then add_trailing_comma(node) end
          end

          for child in node:iter_children() do visit(child) end
        end

        visit(parser:parse()[1]:root())
        table.sort(edits, function(a, b) return a.row > b.row or (a.row == b.row and a.col > b.col) end)
        for _, edit in ipairs(edits) do vim.api.nvim_buf_set_text(bufnr, edit.row, edit.col, edit.row, edit.col, { ',' }) end
      end

      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('ZigMultilineLists', { clear = true }),
        pattern = '*.zig',
        callback = function(args) force_zig_multiline_lists(args.buf) end,
      })

      require('conform').setup {
        notify_on_error = false,
        format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
        default_format_opts = { lsp_format = 'fallback' },
        formatters_by_ft = {
          json = { 'prettier' },
          jsonc = { 'prettier' },
          rust = { 'rustfmt' },
          sql = { 'sqlfluff' },
        },
      }
    end,
  },
}
