return {
  {
    'stevearc/conform.nvim',
    config = function()
      -- `zig fmt` uses a trailing comma as the signal that a list should stay
      -- multiline. Add that signal before Conform asks ZLS to format the file.
      local zig_max_inline_parameters = 3
      local zig_max_inline_expression_length = 100

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

        local function add_trailing_comma(node, last_item)
          local _, _, end_row, end_col = node:range()
          local closing = vim.api.nvim_buf_get_text(bufnr, end_row, end_col - 1, end_row, end_col, {})[1]
          if closing ~= '}' and closing ~= ')' then return end

          if not last_item then return end
          local _, _, row, col = last_item:range()
          local item_line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
          local next_char = item_line:sub(col + 1, col + 1)
          if next_char ~= ',' then table.insert(edits, { row = row, col = col, replacement = { ',' } }) end
        end

        local function add_newline_before(node)
          local row, col = node:range()
          table.insert(edits, { row = row, col = col, replacement = { '', '' } })
        end

        local function add_newline_after(node)
          local _, _, row, col = node:range()
          table.insert(edits, { row = row, col = col, replacement = { '', '' } })
        end

        local function logical_operator(node)
          if not node or node:type() ~= 'binary_expression' then return nil end
          for child in node:iter_children() do
            if child:type() == 'and' or child:type() == 'or' then return child end
          end
          return nil
        end

        local function split_logical_operators(node)
          if node:type() ~= 'binary_expression' then return end
          local operator = logical_operator(node)
          if operator then add_newline_after(operator) end
          for child in node:iter_children() do
            if child:named() and child:type() == 'binary_expression' then split_logical_operators(child) end
          end
        end

        local function visit(node)
          if container_types[node:type()] then
            local fields = 0
            local last_field
            for child in node:iter_children() do
              if child:named() and child:type() == 'container_field' then
                fields = fields + 1
                last_field = child
              end
            end
            if fields > 1 then add_trailing_comma(node, last_field) end
          elseif node:type() == 'parameters' then
            local parameters = 0
            local last_parameter
            for child in node:iter_children() do
              if child:named() and child:type() == 'parameter' then
                parameters = parameters + 1
                last_parameter = child
              end
            end
            if parameters > zig_max_inline_parameters then add_trailing_comma(node, last_parameter) end
          elseif node:type() == 'initializer_list' then
            local fields = 0
            local last_field
            for child in node:iter_children() do
              if child:named() and child:type() == 'assignment_expression' then
                fields = fields + 1
                last_field = child
              end
            end
            if fields > 1 then add_trailing_comma(node, last_field) end
          elseif node:type() == 'if_expression' then
            local start_row, start_col, end_row, end_col = node:range()
            if start_row == end_row and end_col - start_col > zig_max_inline_expression_length then
              local named = {}
              local else_node
              local alternative
              local after_else = false
              for child in node:iter_children() do
                if after_else then
                  alternative = child
                  after_else = false
                end
                if child:named() then
                  table.insert(named, child)
                elseif child:type() == 'else' then
                  else_node = child
                  after_else = true
                end
              end

              if named[2] then add_newline_before(named[2]) end
              if else_node then add_newline_before(else_node) end
              if alternative and alternative:type() ~= 'if_expression' then add_newline_before(alternative) end
            end
          elseif node:type() == 'binary_expression' then
            local operator = logical_operator(node)
            local parent = node:parent()
            local start_row, start_col, end_row, end_col = node:range()
            if operator
              and not logical_operator(parent)
              and start_row == end_row
              and end_col - start_col > zig_max_inline_expression_length
            then
              split_logical_operators(node)
            end
          end

          for child in node:iter_children() do visit(child) end
        end

        visit(parser:parse()[1]:root())
        table.sort(edits, function(a, b) return a.row > b.row or (a.row == b.row and a.col > b.col) end)
        for _, edit in ipairs(edits) do
          vim.api.nvim_buf_set_text(bufnr, edit.row, edit.col, edit.row, edit.col, edit.replacement)
        end
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
          zig = { 'zigfmt' },
          sql = { 'sqlfluff' },
        },
      }
    end,
  },
}
