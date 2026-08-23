return {
  {
    'LintaoAmons/bookmarks.nvim',
    tag = 'v4.0.0',
    dependencies = {
      'kkharji/sqlite.lua',
      'folke/snacks.nvim',
    },
    keys = {
      {
        '<leader>bm',
        '<cmd>BookmarksMark<CR>',
        mode = { 'n', 'v' },
        desc = 'Set Bookmark',
      },
      {
        '<leader><CR>',
        '<cmd>BookmarksGoto<CR>',
        desc = 'Jump to Bookmark',
      },
      {
        '<leader>bM',
        function()
          local picker = require 'bookmarks.picker'
          local service = require 'bookmarks.domain.service'

          picker.pick_bookmark(function(bookmark)
            if not bookmark then return end

            service.remove_bookmark(bookmark.id)
            require('bookmarks.sign').safe_refresh_signs()
            vim.notify(('Deleted bookmark: %s'):format(bookmark.name))
          end, { prompt = 'Delete Bookmark' })
        end,
        desc = 'Delete Bookmark',
      },
    },
    opts = {
      picker = { picker_backend = 'snacks' },
    },
    config = function(_, opts)
      require('bookmarks').setup(opts)

      -- Keep the gutter icon, but omit the plugin's inline name and whole-line
      -- background extmarks.  Names remain available in the picker/database.
      local sign = require 'bookmarks.sign'
      sign.clean()
      sign.place_sign = function(line, buffer)
        vim.fn.sign_place(line, 'BookmarksNvim', 'BookmarksNvimSign', buffer, { lnum = line })
      end
    end,
  },
}
