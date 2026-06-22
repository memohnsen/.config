-- Native Neovim marks keymaps using Snacks.picker

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    -- <leader>ml: View Marks (Jump to mark)
    vim.keymap.set({ 'n', 'v' }, '<leader>ml', function()
      require('snacks').picker.marks({ title = "Marks" })
    end, { desc = 'Nvim Marks' })

    -- <leader>md: Delete Marks Picker
    vim.keymap.set({ 'n', 'v' }, '<leader>md', function()
      require('snacks').picker.marks({
        title = "Delete Marks (Tab to multiselect, CR/C-d to delete)",
        actions = {
          delete_marks = function(picker)
            local items = picker:selected()
            if #items == 0 then
              items = { picker:current() }
            end
            for _, item in ipairs(items) do
              if item and item.label then
                -- escape the label to avoid syntax issues just in case
                pcall(vim.cmd, 'delmarks ' .. item.label)
              end
            end
            -- Clear selection so it doesn't try to reuse deleted items
            picker.list.selection = {}
            -- Refresh the picker list
            picker:find({ refresh = true })
          end,
        },
        win = {
          input = {
            keys = {
              ["<CR>"] = { "delete_marks", desc = "Delete selected marks" },
              ["<C-d>"] = { "delete_marks", desc = "Delete selected marks" },
            }
          }
        }
      })
    end, { desc = 'Delete Marks' })

    -- Register Which-Key descriptions
    pcall(function()
      require('which-key').add {
        { '<leader>m', group = 'Marks' },
      }
    end)
  end,
})
