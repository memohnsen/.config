local gh = function(repo) return 'https://github.com/' .. repo end

vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

vim.pack.add { gh 'rmagatti/auto-session' }

require('auto-session').setup {
  auto_save = true,
  auto_restore = true,
  auto_create = true,
  cwd_change_handling = true,
  git_use_branch_name = true,
  git_auto_restore_on_branch_change = true,
  suppressed_dirs = { '~/Downloads', '/' },
  close_filetypes_on_save = { 'NeogitStatus', 'checkhealth', 'help', 'lazy', 'neo-tree', 'qf', 'trouble' },
  preserve_buffer_on_restore = function() return false end,
  session_lens = {
    picker = 'telescope',
  },
}

local workspace_order_file = vim.fn.stdpath 'data' .. '/auto-session-workspace-order'

local function read_workspace_order()
  if vim.fn.filereadable(workspace_order_file) ~= 1 then return {} end
  return vim.fn.readfile(workspace_order_file)
end

local function write_workspace_order(order)
  vim.fn.mkdir(vim.fn.fnamemodify(workspace_order_file, ':h'), 'p')
  vim.fn.writefile(order, workspace_order_file)
end

local function remember_workspace(session_name)
  if not session_name or session_name == '' then return end

  local order = read_workspace_order()
  for _, existing in ipairs(order) do
    if existing == session_name then return end
  end

  table.insert(order, session_name)
  write_workspace_order(order)
end

local function rename_workspace_in_order(old_name, new_name)
  if not old_name or old_name == '' or not new_name or new_name == '' then return end

  local order = read_workspace_order()
  local renamed = false
  local seen = {}
  local updated = {}

  for _, session_name in ipairs(order) do
    local next_name = session_name
    if session_name == old_name then
      next_name = new_name
      renamed = true
    end

    if not seen[next_name] then
      table.insert(updated, next_name)
      seen[next_name] = true
    end
  end

  if not renamed and not seen[new_name] then table.insert(updated, new_name) end

  write_workspace_order(updated)
end

local function sort_workspaces_by_saved_order(sessions)
  local order = read_workspace_order()
  local order_index = {}
  for index, session_name in ipairs(order) do
    order_index[session_name] = index
  end

  table.sort(sessions, function(left, right)
    local left_index = order_index[left.session_name]
    local right_index = order_index[right.session_name]

    if left_index and right_index then return left_index < right_index end
    if left_index ~= right_index then return left_index ~= nil end

    return left.display_name < right.display_name
  end)

  local known = {}
  for _, session in ipairs(sessions) do
    known[session.session_name] = true
  end

  local pruned_order = {}
  for _, session_name in ipairs(order) do
    if known[session_name] then table.insert(pruned_order, session_name) end
  end
  for _, session in ipairs(sessions) do
    if not order_index[session.session_name] then table.insert(pruned_order, session.session_name) end
  end

  write_workspace_order(pruned_order)
end

local function set_diagnostics_enabled(enabled)
  if vim.diagnostic.enable then
    vim.diagnostic.enable(enabled)
  elseif enabled then
    vim.diagnostic.enable()
  else
    vim.diagnostic.disable()
  end
end

local function stop_lsp_clients()
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop()
  end
end

local function restore_workspace(session_name)
  local auto_session = require 'auto-session'

  set_diagnostics_enabled(false)
  stop_lsp_clients()

  vim.defer_fn(function()
    local ok, err = pcall(auto_session.autosave_and_restore, session_name)

    vim.defer_fn(function()
      set_diagnostics_enabled(true)
      vim.diagnostic.reset()
    end, 500)

    if not ok then vim.notify('Workspace restore failed: ' .. tostring(err), vim.log.levels.ERROR) end
  end, 100)
end

local workspace_cycle = {
  signatures = {},
  sessions = {},
  index = nil,
}

local function recent_workspaces()
  local auto_session = require 'auto-session'
  local lib = require 'auto-session.lib'
  local sessions = lib.get_session_list(auto_session.get_root_dir())

  sort_workspaces_by_saved_order(sessions)

  return sessions
end

local function current_workspace_name()
  if vim.v.this_session == '' then return nil end

  return require('auto-session.lib').escaped_session_path_to_session_name(vim.v.this_session)
end

local function session_signatures(sessions)
  return vim.tbl_map(function(session) return session.session_name .. '\n' .. session.path end, sessions)
end

local function cycle_needs_refresh(sessions)
  local signatures = session_signatures(sessions)
  if #signatures ~= #workspace_cycle.signatures then return true, signatures end

  for index, signature in ipairs(signatures) do
    if workspace_cycle.signatures[index] ~= signature then return true, signatures end
  end

  return false, signatures
end

local function refresh_workspace_cycle(sessions, signatures)
  workspace_cycle.sessions = sessions
  workspace_cycle.signatures = signatures
  workspace_cycle.index = nil

  local current = current_workspace_name()
  if not current then return end

  for index, session in ipairs(sessions) do
    if session.session_name == current then
      workspace_cycle.index = index
      return
    end
  end
end

local function cycle_workspace()
  local sessions = recent_workspaces()
  if vim.tbl_isempty(sessions) then
    vim.notify('No saved workspaces yet', vim.log.levels.INFO)
    return
  end

  local needs_refresh, signatures = cycle_needs_refresh(sessions)
  if needs_refresh then refresh_workspace_cycle(sessions, signatures) end

  workspace_cycle.index = (workspace_cycle.index or 0) + 1
  if workspace_cycle.index > #workspace_cycle.sessions then workspace_cycle.index = 1 end

  local session = workspace_cycle.sessions[workspace_cycle.index]
  vim.notify('Switching workspace: ' .. session.display_name, vim.log.levels.INFO)
  restore_workspace(session.session_name)
end

local function has_modified_listed_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted and vim.bo[bufnr].modified then return true end
  end

  return false
end

local function close_listed_buffers_except_current()
  local current = vim.api.nvim_get_current_buf()

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= current and vim.bo[bufnr].buflisted then pcall(vim.api.nvim_buf_delete, bufnr, {}) end
  end
end

local function new_workspace()
  if has_modified_listed_buffers() then
    vim.notify('Save or discard modified buffers before creating a new workspace', vim.log.levels.WARN)
    return
  end

  if vim.fn.executable 'zoxide' ~= 1 then
    vim.notify('zoxide is not installed', vim.log.levels.ERROR)
    return
  end

  local dirs = vim.fn.systemlist { 'zoxide', 'query', '-l' }
  if vim.tbl_isempty(dirs) then
    vim.notify('zoxide has no directory history yet', vim.log.levels.INFO)
    return
  end

  vim.ui.select(dirs, { prompt = 'New workspace from project:' }, function(choice)
    if not choice or choice == '' then return end

    local auto_session = require 'auto-session'
    auto_session.auto_save_session()

    vim.cmd.cd(vim.fn.fnameescape(choice))

    vim.cmd.tabonly()
    vim.cmd.enew()
    close_listed_buffers_except_current()

    local name = vim.fn.fnamemodify(choice, ':t')
    if auto_session.save_session(name, { show_message = true }) then remember_workspace(name) end
  end)
end

local function save_workspace_as()
  vim.ui.input({
    prompt = 'Workspace name: ',
    default = current_workspace_name() or vim.fn.fnamemodify(vim.fn.getcwd(), ':t'),
  }, function(name)
    name = vim.trim(name or '')
    if name == '' then return end

    if require('auto-session').save_session(name, { show_message = true }) then remember_workspace(name) end
  end)
end

local function rename_current_workspace()
  local old_name = current_workspace_name()
  if not old_name then
    vim.notify('No current workspace to rename', vim.log.levels.WARN)
    return
  end

  vim.ui.input({
    prompt = 'Rename workspace: ',
    default = old_name,
  }, function(new_name)
    new_name = vim.trim(new_name or '')
    if new_name == '' or new_name == old_name then return end

    local auto_session = require 'auto-session'
    if not auto_session.save_session(new_name, { show_message = true }) then return end

    rename_workspace_in_order(old_name, new_name)
    workspace_cycle.signatures = {}
    workspace_cycle.sessions = {}
    workspace_cycle.index = nil

    pcall(auto_session.delete_session, old_name)
    vim.notify('Renamed workspace: ' .. old_name .. ' -> ' .. new_name, vim.log.levels.INFO)
  end)
end

local function switch_to_workspace_number(index)
  return function()
    local sessions = recent_workspaces()
    local session = sessions[index]
    if not session then
      vim.notify('No workspace #' .. index, vim.log.levels.INFO)
      return
    end

    vim.notify('Switching workspace: ' .. session.display_name, vim.log.levels.INFO)
    restore_workspace(session.session_name)
  end
end

vim.keymap.set('n', '<leader><Tab>.', '<cmd>AutoSession search<CR>', { desc = 'Search Sessions' })
vim.keymap.set('n', '<leader><Tab><Tab>', cycle_workspace, { desc = 'Next Workspace' })
vim.keymap.set('n', '<leader><Tab>n', new_workspace, { desc = 'New Workspace' })
vim.keymap.set('n', '<leader><Tab>r', rename_current_workspace, { desc = 'Rename Workspace' })
vim.keymap.set('n', '<leader><Tab>s', save_workspace_as, { desc = 'Save Workspace As' })
vim.keymap.set('n', '<leader><Tab>d', function()
  local name = current_workspace_name()
  if not name then
    vim.notify('No current workspace to delete', vim.log.levels.WARN)
    return
  end

  local auto_session = require 'auto-session'
  pcall(auto_session.delete_session, name)

  local order = read_workspace_order()
  local pruned = vim.tbl_filter(function(entry) return entry ~= name end, order)
  write_workspace_order(pruned)

  workspace_cycle.signatures = {}
  workspace_cycle.sessions = {}
  workspace_cycle.index = nil

  vim.cmd.tabonly()
  vim.cmd.enew()
  close_listed_buffers_except_current()

  vim.notify('Deleted workspace: ' .. name, vim.log.levels.INFO)
end, { desc = 'Delete Workspace' })

for index = 1, 9 do
  vim.keymap.set('n', '<leader><Tab>' .. index, switch_to_workspace_number(index), { desc = 'Workspace ' .. index })
end

pcall(function()
  local mappings = {
    { '<leader><Tab>', group = 'Workspace' },
    { '<leader><Tab>.', desc = 'Search Sessions' },
    { '<leader><Tab><Tab>', desc = 'Next Workspace' },
    { '<leader><Tab>n', desc = 'New Workspace' },
    { '<leader><Tab>r', desc = 'Rename Workspace' },
    { '<leader><Tab>s', desc = 'Save Workspace As' },
    { '<leader><Tab>d', desc = 'Delete Workspace' },
  }

  for index = 1, 9 do
    table.insert(mappings, { '<leader><Tab>' .. index, desc = 'Workspace ' .. index })
  end

  require('which-key').add(mappings)
end)
