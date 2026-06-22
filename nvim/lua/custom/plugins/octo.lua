vim.pack.add {
  { src = 'https://github.com/pwntester/octo.nvim', version = 'master' },
}

require('octo').setup {
  picker = 'telescope',
  enable_builtin = true,
  default_remote = { 'upstream', 'origin' },
}

if vim.fn.executable 'gh' ~= 1 then vim.notify('octo.nvim needs the GitHub CLI: install gh and run gh auth login', vim.log.levels.WARN) end

vim.keymap.set('n', '<leader>go', '<cmd>Octo<CR>', { desc = 'Octo Commands' })
vim.keymap.set('n', '<leader>gn', '<cmd>Octo notification list<CR>', { desc = 'GitHub Notifications' })
vim.keymap.set('n', '<leader>gb', '<cmd>Octo repo browser<CR>', { desc = 'Open Repo Browser' })

vim.keymap.set('n', '<leader>gil', '<cmd>Octo issue list<CR>', { desc = 'List Issues' })
vim.keymap.set('n', '<leader>gic', '<cmd>Octo issue create<CR>', { desc = 'Create Issue' })
vim.keymap.set('n', '<leader>gix', '<cmd>Octo issue close<CR>', { desc = 'Close Issue' })
vim.keymap.set('n', '<leader>gib', '<cmd>Octo issue browser<CR>', { desc = 'Open Issue URL' })

vim.keymap.set('n', '<leader>gpl', '<cmd>Octo pr list<CR>', { desc = 'List PRs' })
vim.keymap.set('n', '<leader>gpc', '<cmd>Octo pr create<CR>', { desc = 'Create PR' })
vim.keymap.set('n', '<leader>gps', '<cmd>Octo review start<CR>', { desc = 'Start PR Review' })
vim.keymap.set('n', '<leader>gpr', '<cmd>Octo review resume<CR>', { desc = 'Resume PR Review' })
vim.keymap.set('n', '<leader>gpb', '<cmd>Octo pr browser<CR>', { desc = 'Open PR URL' })

pcall(
  function()
    require('which-key').add {
      { '<leader>go', desc = 'Octo Commands' },
      { '<leader>gn', desc = 'GitHub Notifications' },
      { '<leader>gb', desc = 'Open Repo Browser' },

      { '<leader>gi', group = 'Github Issues' },
      { '<leader>gil', desc = 'List Issues' },
      { '<leader>gic', desc = 'Create Issue' },
      { '<leader>gib', desc = 'Open Issue Browser' },

      { '<leader>gp', group = 'Github PRs' },
      { '<leader>gpl', desc = 'List PRs' },
      { '<leader>gpc', desc = 'Create PR' },
      { '<leader>gps', desc = 'Start PR Review' },
      { '<leader>gpr', desc = 'Resume PR Review' },
      { '<leader>gpb', desc = 'Open PR Browser' },
    }
  end
)
