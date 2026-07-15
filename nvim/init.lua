-- Core settings and plugin bootstrap. Individual plugin setups live in lua/custom/plugins.
do
  -- Fall back to $HOME if Neovim starts from a directory that was deleted.
  if not vim.uv.cwd() then vim.cmd.cd() end

  vim.loader.enable()
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '
  vim.g.have_nerd_font = true
  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.mouse = 'a'
  vim.o.showmode = false
  vim.o.breakindent = true
  vim.o.undofile = true
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.signcolumn = 'yes'
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300
  vim.o.splitright = true
  vim.o.splitbelow = true
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
  vim.o.inccommand = 'split'
  vim.o.cursorline = true
  vim.o.scrolloff = 20
  vim.o.confirm = true
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },
    virtual_text = { current_line = false },
    virtual_lines = false,
    jump = {
      on_jump = function(_, bufnr) vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false } end,
    },
  }

  local diagnostic_float_augroup = vim.api.nvim_create_augroup('kickstart-diagnostic-float', { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    group = diagnostic_float_augroup,
    callback = function() vim.diagnostic.open_float { scope = 'cursor', focus = false } end,
  })

  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local result = vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  }
  if vim.v.shell_error ~= 0 then error('Failed to install lazy.nvim:\n' .. result) end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup(require 'custom.plugins', {
  lockfile = vim.fn.stdpath 'config' .. '/lazy-lock.json',
  install = { colorscheme = { 'onedark' } },
  checker = { enabled = false },
})

require 'custom.plugins.keymaps'()
