return {
  {
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = {
      { 'L3MON4D3/LuaSnip', version = '2.*', build = vim.fn.executable 'make' == 1 and 'make install_jsregexp' or nil },
    },
    config = function()
      local luasnip = require 'luasnip'
      luasnip.setup {}

      local ls = require 'luasnip'

      ls.add_snippets('rust', {
        ls.snippet('test', {
          ls.text_node '#[test]',
        }),

        ls.snippet('cfgtest', {
          ls.text_node { '#[cfg(test)]', 'mod tests {', 'use super::*;', '', '#[test]', '', '}' },
        }),
      })

      ls.add_snippets('zig', {
        ls.snippet('tte', {
          ls.text_node 'try testing.expect(',
          ls.insert_node(1),
          ls.text_node ');',
        }),

        ls.snippet('std', {
          ls.text_node 'const std = @import("std");',
        }),

        ls.snippet('mem', {
          ls.text_node 'const mem = std.mem;',
        }),

        ls.snippet('testing', {
          ls.text_node 'const testing = std.testing;',
        }),

        ls.snippet('tst', {
          ls.text_node 'test "',
          ls.insert_node(1),
          ls.text_node { '" {', '  var ' },
          ls.insert_node(2),
          ls.text_node ' = ',
          ls.insert_node(3),
          ls.text_node { '{};', '  const allocator = testing.allocator;', '  defer ' },
          ls.insert_node(4),
          ls.text_node { '.deinit(allocator);', '}' },
        }),
      })

      local function finish_zig_import()
        if vim.bo.filetype ~= 'zig' then return end

        local bufnr = vim.api.nvim_get_current_buf()
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1

        local function add_semicolon()
          if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'zig' then return true end
          local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
          if not line then return true end

          local content = line:gsub('%s+$', '')
          if content:sub(-1) == ';' then return true end
          if not content:match '@import%s*%b()$' then return false end

          vim.api.nvim_buf_set_text(bufnr, row, #content, row, #content, { ';' })
          return true
        end

        -- Function-kind brackets are present immediately. Semantic-token
        -- brackets can arrive asynchronously, so retry after Blink's timeout.
        if not add_semicolon() then vim.defer_fn(add_semicolon, 450) end
      end

      require('blink.cmp').setup {
        keymap = {
          preset = 'enter',
          ['<CR>'] = {
            function(cmp) return cmp.select_and_accept { callback = finish_zig_import } end,
            'fallback',
          },
          ['<C-y>'] = {
            function(cmp) return cmp.select_and_accept { callback = finish_zig_import } end,
          },
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
        snippets = { preset = 'luasnip' },
        appearance = { nerd_font_variant = 'mono' },
        completion = {
          accept = { auto_brackets = { enabled = true } },
          documentation = { auto_show = true, auto_show_delay_ms = 200 },
          list = { selection = { preselect = true, auto_insert = false } },
        },
        sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
        cmdline = {
          enabled = true,
          keymap = { preset = 'cmdline', ['<Right>'] = false, ['<Left>'] = false },
          completion = {
            list = { selection = { preselect = false } },
            menu = { auto_show = function() return vim.fn.getcmdtype() == ':' end },
            ghost_text = { enabled = true },
          },
        },
      }

      local function accept_completion_or(fallback)
        return function()
          local cmp = require 'blink.cmp'
          if cmp.is_visible() or cmp.is_active() then
            cmp.select_and_accept { callback = finish_zig_import }
            return ''
          end
          if type(fallback) == 'function' then return fallback() end
          return fallback
        end
      end

      local function pair_break_cr()
        local _, col = unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_get_current_line()
        local pairs = { ['('] = ')', ['['] = ']', ['{'] = '}', ['"'] = '"', ["'"] = "'" }
        if pairs[line:sub(col, col)] ~= line:sub(col + 1, col + 1) then return '\r' end

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

      local function tab_completion()
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

      local function shift_tab_completion()
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

      vim.api.nvim_create_autocmd('InsertEnter', {
        callback = function(args)
          if vim.bo[args.buf].buftype ~= '' then return end
          local opts = { buffer = args.buf, expr = true, silent = true, replace_keycodes = true }
          vim.keymap.set('i', '<CR>', accept_completion_or(pair_break_cr), opts)
          vim.keymap.set('i', '<Tab>', tab_completion, opts)
          vim.keymap.set('i', '<S-Tab>', shift_tab_completion, opts)
        end,
      })
    end,
  },
}
