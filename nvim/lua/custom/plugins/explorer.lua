vim.pack.add {
  { src = 'https://github.com/folke/snacks.nvim', branch = 'main' },
}

require('snacks').setup {
  explorer = {
    replace_netrw = false,
  },
  picker = {
    sources = {
      explorer = {
        hidden = false,
        ignored = true,
        jump = { close = true },
      },
      files = {
        hidden = true,
        ignored = true,
        exclude = { 'target', 'target/**' },
      },
      grep = {
        hidden = false,
        ignored = true,
        exclude = { 'target', 'target/**' },
      },
      git_status = {
        ignored = true,
      },
    },
  },
}

local function project_root()
  local git_root = vim.fn.systemlist { 'git', 'rev-parse', '--show-toplevel' }
  if vim.v.shell_error == 0 and git_root[1] and git_root[1] ~= '' then return git_root[1] end

  return vim.fn.getcwd()
end

local function open_explorer(cwd)
  if Snacks and Snacks.explorer then
    Snacks.explorer { cwd = cwd }
    return
  end

  require('snacks').picker.explorer { cwd = cwd }
end

vim.keymap.set('n', '<leader>e', function() open_explorer(project_root()) end, { desc = 'Explorer Root' })

pcall(function()
  require('which-key').add {
    { '<leader>e', desc = 'File Explorer' },
  }
end)
