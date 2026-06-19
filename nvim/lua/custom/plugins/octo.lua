vim.pack.add {
  { src = 'https://github.com/pwntester/octo.nvim', version = 'master' },
}

require('octo').setup {
  picker = 'telescope',
  enable_builtin = true,
  default_remote = { 'upstream', 'origin' },
}

if vim.fn.executable 'gh' ~= 1 then
  vim.notify('octo.nvim needs the GitHub CLI: install gh and run gh auth login', vim.log.levels.WARN)
end

vim.keymap.set('n', '<leader>gO', '<cmd>Octo<CR>', { desc = 'Octo Commands' })
vim.keymap.set('n', '<leader>gi', '<cmd>Octo issue list<CR>', { desc = 'GitHub Issues' })
vim.keymap.set('n', '<leader>gI', '<cmd>Octo issue create<CR>', { desc = 'Create GitHub Issue' })
vim.keymap.set('n', '<leader>gp', '<cmd>Octo pr list<CR>', { desc = 'GitHub Pull Requests' })
vim.keymap.set('n', '<leader>gP', '<cmd>Octo pr create<CR>', { desc = 'Create GitHub Pull Request' })
vim.keymap.set('n', '<leader>gr', '<cmd>Octo review start<CR>', { desc = 'Start PR Review' })
vim.keymap.set('n', '<leader>gR', '<cmd>Octo review resume<CR>', { desc = 'Resume PR Review' })
vim.keymap.set('n', '<leader>gn', '<cmd>Octo notification list<CR>', { desc = 'GitHub Notifications' })
vim.keymap.set('n', '<leader>gs', function()
  require('octo.utils').create_base_search_command { include_current_repo = true }
end, { desc = 'Search GitHub' })

pcall(function()
  require('which-key').add {
    { '<leader>gO', desc = 'Octo Commands' },
    { '<leader>gi', desc = 'GitHub Issues' },
    { '<leader>gI', desc = 'Create GitHub Issue' },
    { '<leader>gp', desc = 'GitHub Pull Requests' },
    { '<leader>gP', desc = 'Create GitHub Pull Request' },
    { '<leader>gr', desc = 'Start PR Review' },
    { '<leader>gR', desc = 'Resume PR Review' },
    { '<leader>gn', desc = 'GitHub Notifications' },
    { '<leader>gs', desc = 'Search GitHub' },
  }
end)
