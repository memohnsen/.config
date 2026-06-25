vim.pack.add {
  { src = 'https://github.com/folke/snacks.nvim', branch = 'main' },
}

require('snacks').setup {
  explorer = {
    replace_netrw = false,
  },
  -- Image preview (Kitty graphics protocol, supported by Ghostty).
  -- doc.enabled = false disables auto inline rendering; instead pressing <CR>
  -- on an image link in an org file pops up a floating preview via
  -- Snacks.image.hover() (see orgmode.lua). Move the cursor to close it.
  image = {
    enabled = true,
    doc = {
      enabled = false, -- no auto rendering; preview on demand with <CR>
      inline = false,
      float = true,
      max_width = 80,
      max_height = 40,
    },
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
