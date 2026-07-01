local gh = function(repo) return 'https://github.com/' .. repo end

vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

vim.pack.add { gh 'rmagatti/auto-session' }

local function open_workspaces()
  _G.kickstart_open_workspaces = _G.kickstart_open_workspaces or {}
  return _G.kickstart_open_workspaces
end

local function mark_workspace_open(session_name)
  if not session_name or session_name == '' then return end

  local workspaces = open_workspaces()
  for _, existing in ipairs(workspaces) do
    if existing == session_name then return end
  end

  table.insert(workspaces, session_name)
end

local function remove_open_workspace(session_name)
  if not session_name or session_name == '' then return end

  local updated = {}
  for _, existing in ipairs(open_workspaces()) do
    if existing ~= session_name then table.insert(updated, existing) end
  end

  _G.kickstart_open_workspaces = updated
end

local function rename_open_workspace(old_name, new_name)
  if not old_name or old_name == '' or not new_name or new_name == '' then return end

  local updated = {}
  local seen = {}
  for _, existing in ipairs(open_workspaces()) do
    local next_name = existing == old_name and new_name or existing
    if not seen[next_name] then
      table.insert(updated, next_name)
      seen[next_name] = true
    end
  end

  _G.kickstart_open_workspaces = updated
end

require('auto-session').setup {
  auto_save = true,
  auto_restore = true,
  auto_create = false,
  auto_delete_empty_sessions = false,
  cwd_change_handling = true,
  git_use_branch_name = false,
  git_auto_restore_on_branch_change = false,
  suppressed_dirs = { '~/Downloads', '/' },
  close_filetypes_on_save = { 'NeogitStatus', 'checkhealth', 'help', 'lazy', 'neo-tree', 'qf', 'trouble' },
  preserve_buffer_on_restore = function() return false end,
  session_lens = {
    picker = 'telescope',
  },
  post_restore_cmds = {
    function(session_name) mark_workspace_open(session_name) end,
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
  local updated = { session_name }
  for _, existing in ipairs(order) do
    if existing ~= session_name then table.insert(updated, existing) end
  end

  write_workspace_order(updated)
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

local function is_branch_workspace(session)
  return session.session_name and session.session_name:find('|', 1, true) ~= nil
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
    local ok, restored = pcall(auto_session.autosave_and_restore, session_name)

    vim.defer_fn(function()
      set_diagnostics_enabled(true)
      vim.diagnostic.reset()
    end, 500)

    if ok and restored ~= false then
      mark_workspace_open(session_name)
      remember_workspace(session_name)
    elseif not ok then
      vim.notify('Workspace restore failed: ' .. tostring(restored), vim.log.levels.ERROR)
    end
  end, 100)
end

local workspace_cycle = {
  signatures = {},
  sessions = {},
  index = nil,
}

local function reset_workspace_cycle()
  workspace_cycle.signatures = {}
  workspace_cycle.sessions = {}
  workspace_cycle.index = nil
end

local function remove_workspace_from_order(session_name)
  local order = read_workspace_order()
  local pruned = vim.tbl_filter(function(entry) return entry ~= session_name end, order)
  write_workspace_order(pruned)
end

local function recent_workspaces()
  local auto_session = require 'auto-session'
  local lib = require 'auto-session.lib'
  local sessions = lib.get_session_list(auto_session.get_root_dir())

  sessions = vim.tbl_filter(function(session) return not is_branch_workspace(session) end, sessions)

  sort_workspaces_by_saved_order(sessions)

  return sessions
end

local function current_workspace_name()
  if vim.v.this_session == '' then return nil end

  return require('auto-session.lib').escaped_session_path_to_session_name(vim.v.this_session)
end

local function open_workspace_sessions()
  local saved_sessions = recent_workspaces()
  local session_by_name = {}
  for _, session in ipairs(saved_sessions) do
    session_by_name[session.session_name] = session
  end

  local sessions = {}
  local seen = {}
  for _, session_name in ipairs(open_workspaces()) do
    local session = session_by_name[session_name]
    if session and not seen[session_name] then
      table.insert(sessions, session)
      seen[session_name] = true
    end
  end

  local current = current_workspace_name()
  if current and not seen[current] then
    table.insert(sessions, session_by_name[current] or { session_name = current, display_name = current, path = vim.v.this_session })
  end

  return sessions
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
  local sessions = open_workspace_sessions()
  if vim.tbl_isempty(sessions) then
    vim.notify('No open workspaces yet', vim.log.levels.INFO)
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

local function save_workspace_after_first_file(name)
  local group = vim.api.nvim_create_augroup('kickstart_workspace_first_file_' .. vim.fn.sha256(name), { clear = true })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufReadPost' }, {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      local file = vim.api.nvim_buf_get_name(bufnr)
      if file == '' or vim.bo[bufnr].buftype ~= '' then return end

      vim.api.nvim_del_augroup_by_id(group)
      vim.schedule(function()
        if require('auto-session').save_session(name, { show_message = true }) then
          mark_workspace_open(name)
          reset_workspace_cycle()
        end
      end)
    end,
  })
end

local function pick_initial_workspace_file(cwd, name)
  save_workspace_after_first_file(name)

  ---@type boolean, any
  local ok, snacks = pcall(require, 'snacks')
  if ok and snacks.picker and snacks.picker.files then
    snacks.picker.files {
      cwd = cwd,
      title = 'Open workspace file',
      hidden = true,
      ignored = true,
    }
    return
  end

  require('telescope.builtin').find_files {
    cwd = cwd,
    prompt_title = 'Open workspace file',
  }
end

local function select_workspace(prompt, on_choice)
  local sessions = recent_workspaces()
  if vim.tbl_isempty(sessions) then
    vim.notify('No saved workspaces yet', vim.log.levels.INFO)
    return
  end

  vim.ui.select(sessions, {
    prompt = prompt,
    kind = 'workspace',
    format_item = function(item) return item.display_name end,
  }, function(choice)
    if choice then on_choice(choice) end
  end)
end

local function select_closed_workspace(prompt, on_choice)
  local open = {}
  for _, session_name in ipairs(open_workspaces()) do
    open[session_name] = true
  end

  local sessions = vim.tbl_filter(function(session) return not open[session.session_name] end, recent_workspaces())
  if vim.tbl_isempty(sessions) then
    vim.notify('No closed saved workspaces', vim.log.levels.INFO)
    return
  end

  vim.ui.select(sessions, {
    prompt = prompt,
    kind = 'workspace',
    format_item = function(item) return item.display_name end,
  }, function(choice)
    if choice then on_choice(choice) end
  end)
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
    if auto_session.save_session(name, { show_message = true }) then
      remember_workspace(name)
      mark_workspace_open(name)
      reset_workspace_cycle()
      vim.schedule(function() pick_initial_workspace_file(choice, name) end)
    end
  end)
end

local function save_workspace()
  local name = current_workspace_name()
  if not name then
    vim.notify('No saved workspace is active. Use <leader><Tab>n or <leader><Tab>S first.', vim.log.levels.WARN)
    return
  end

  if require('auto-session').save_session(name, { show_message = true }) then
    remember_workspace(name)
    mark_workspace_open(name)
    reset_workspace_cycle()
  end
end

local function save_workspace_as()
  vim.ui.input({
    prompt = 'Workspace name: ',
    default = current_workspace_name() or vim.fn.fnamemodify(vim.fn.getcwd(), ':t'),
  }, function(name)
    name = vim.trim(name or '')
    if name == '' then return end

    if require('auto-session').save_session(name, { show_message = true }) then
      remember_workspace(name)
      mark_workspace_open(name)
      reset_workspace_cycle()
    end
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
    rename_open_workspace(old_name, new_name)
    reset_workspace_cycle()

    pcall(auto_session.delete_session, old_name)
    vim.notify('Renamed workspace: ' .. old_name .. ' -> ' .. new_name, vim.log.levels.INFO)
  end)
end

local function switch_to_workspace_number(index)
  return function()
    local sessions = open_workspace_sessions()
    local session = sessions[index]
    if not session then
      vim.notify('No open workspace #' .. index, vim.log.levels.INFO)
      return
    end

    vim.notify('Switching workspace: ' .. session.display_name, vim.log.levels.INFO)
    restore_workspace(session.session_name)
  end
end

local function load_workspace()
  select_closed_workspace('Load workspace:', function(session)
    vim.notify('Switching workspace: ' .. session.display_name, vim.log.levels.INFO)
    restore_workspace(session.session_name)
  end)
end

local function close_workspace()
  local auto_session = require 'auto-session'
  local name = current_workspace_name()

  if name then auto_session.auto_save_session() end

  remove_open_workspace(name)
  vim.v.this_session = ''
  auto_session.manually_named_session = false
  reset_workspace_cycle()

  local next_workspace = open_workspace_sessions()[1]
  if next_workspace then
    vim.notify('Closed workspace: ' .. name, vim.log.levels.INFO)
    vim.notify('Switching workspace: ' .. next_workspace.display_name, vim.log.levels.INFO)
    restore_workspace(next_workspace.session_name)
    return
  end

  vim.cmd.tabonly()
  vim.cmd.enew()
  close_listed_buffers_except_current()

  vim.notify(name and ('Closed workspace: ' .. name) or 'Closed workspace', vim.log.levels.INFO)
end

local function delete_workspace(session)
  local auto_session = require 'auto-session'
  local deleted = auto_session.delete_session_file(session.path, session.display_name)
  if not deleted then return end

  remove_workspace_from_order(session.session_name)
  remove_open_workspace(session.session_name)
  reset_workspace_cycle()
end

local function delete_workspace_from_list()
  select_workspace('Delete saved workspace:', function(session)
    delete_workspace(session)
  end)
end

vim.keymap.set('n', '<leader><Tab>.', '<cmd>AutoSession search<CR>', { desc = 'Search Sessions' })
vim.keymap.set('n', '<leader><Tab><Tab>', cycle_workspace, { desc = 'Next Workspace' })
vim.keymap.set('n', '<leader><Tab>l', load_workspace, { desc = 'Load Workspace' })
vim.keymap.set('n', '<leader><Tab>n', new_workspace, { desc = 'New Workspace' })
vim.keymap.set('n', '<leader><Tab>r', rename_current_workspace, { desc = 'Rename Workspace' })
vim.keymap.set('n', '<leader><Tab>s', save_workspace, { desc = 'Save Workspace' })
vim.keymap.set('n', '<leader><Tab>S', save_workspace_as, { desc = 'Save Workspace As' })
vim.keymap.set('n', '<leader><Tab>d', close_workspace, { desc = 'Close Workspace' })
vim.keymap.set('n', '<leader><Tab>D', delete_workspace_from_list, { desc = 'Delete Saved Workspace' })

for index = 1, 9 do
  vim.keymap.set('n', '<leader><Tab>' .. index, switch_to_workspace_number(index), { desc = 'Workspace ' .. index })
end

pcall(function()
  local mappings = {
    { '<leader><Tab>', group = 'Workspace' },
    { '<leader><Tab>.', desc = 'Search Sessions' },
    { '<leader><Tab><Tab>', desc = 'Next Workspace' },
    { '<leader><Tab>l', desc = 'Load Workspace' },
    { '<leader><Tab>n', desc = 'New Workspace' },
    { '<leader><Tab>r', desc = 'Rename Workspace' },
    { '<leader><Tab>s', desc = 'Save Workspace' },
    { '<leader><Tab>S', desc = 'Save Workspace As' },
    { '<leader><Tab>d', desc = 'Close Workspace' },
    { '<leader><Tab>D', desc = 'Delete Saved Workspace' },
  }

  for index = 1, 9 do
    table.insert(mappings, { '<leader><Tab>' .. index, desc = 'Workspace ' .. index })
  end

  require('which-key').add(mappings)
end)
