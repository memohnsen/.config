local gh = function(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'kkharji/sqlite.lua' }
vim.pack.add { gh 'LintaoAmons/bookmarks.nvim' }

-- Setup bookmarks after all plugins have loaded (using VimEnter autocmd),
-- which prevents plugin/bookmarks.lua from overwriting vim.g.bookmarks_config with nil.
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    require('bookmarks').setup {
      -- Optional signs and icons customization
      signs = {
        mark = { icon = '󰃁', color = 'red', line_bg = '#572626' },
      },
      picker = {
        -- Set to "snacks" or "telescope" depending on preferences.
        -- Both are installed, but snacks is the default and fits well.
        picker_backend = 'snacks',
      },
    }

    -- Setup keymaps
    vim.keymap.set({ 'n', 'v' }, '<leader>mm', '<cmd>BookmarksMark<cr>', { desc = 'Toggle Mark' })
    vim.keymap.set({ 'n', 'v' }, '<leader>mn', '<cmd>BookmarksGotoNext<cr>', { desc = 'Toggle Next' })
    vim.keymap.set({ 'n', 'v' }, '<leader>ms', '<cmd>BookmarksGoto<cr>', { desc = 'Go to Bookmark' })
    vim.keymap.set({ 'n', 'v' }, '<leader>mc', '<cmd>BookmarksCommands<cr>', { desc = 'Bookmark Commands' })
    vim.keymap.set({ 'n', 'v' }, '<leader><cr>', function()
      require('bookmarks.picker').pick_bookmark(function(bookmark)
        if bookmark then
          require('bookmarks.domain.service').goto_bookmark(bookmark.id)
          require('bookmarks.sign').safe_refresh_signs()
        end
      end, {
        bookmarks = require('bookmarks.domain.repo').get_all_bookmarks(),
        prompt = 'All Bookmarks',
      })
    end, { desc = 'Find All Bookmarks' })

    vim.keymap.set({ 'n', 'v' }, '<leader>md', function()
      local repo = require 'bookmarks.domain.repo'
      local marks = repo.get_all_bookmarks()
      for _, mark in ipairs(marks) do
        repo.delete_node(mark.id)
      end
      require('bookmarks.sign').safe_refresh_signs()
      pcall(require('bookmarks.tree.operate').refresh)
      vim.notify('Deleted ' .. #marks .. ' bookmarks', vim.log.levels.INFO)
    end, { desc = 'Delete All Bookmarks' })

    -- Register Which-Key descriptions
    pcall(function()
      require('which-key').add {
        { '<leader>m', group = 'Bookmarks' },
      }
    end)
  end,
})
