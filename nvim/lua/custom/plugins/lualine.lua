vim.pack.add {
  { src = 'https://github.com/nvim-lualine/lualine.nvim', branch = 'master' },
}

local org_dir = vim.fn.expand '~/dev/org'
local workspace_order_file = vim.fn.stdpath 'data' .. '/auto-session-workspace-order'

local function read_workspace_order()
  if vim.fn.filereadable(workspace_order_file) ~= 1 then return {} end
  return vim.fn.readfile(workspace_order_file)
end

local function sort_workspaces_by_saved_order(sessions)
  local order_index = {}
  for index, session_name in ipairs(read_workspace_order()) do
    order_index[session_name] = index
  end

  table.sort(sessions, function(left, right)
    local left_index = order_index[left.session_name]
    local right_index = order_index[right.session_name]

    if left_index and right_index then return left_index < right_index end
    if left_index ~= right_index then return left_index ~= nil end

    return left.display_name < right.display_name
  end)
end

local function workspace_display_name(session)
  local name = session.display_name or session.session_name or ''
  name = name:gsub('^~/', ''):gsub('^' .. vim.pesc(vim.fn.expand '~') .. '/', '')
  return vim.fn.fnamemodify(name, ':t')
end

local function is_branch_workspace(session)
  return session.session_name and session.session_name:find('|', 1, true) ~= nil
end

local function current_workspace_name()
  if vim.v.this_session == '' then return nil end

  local ok, lib = pcall(require, 'auto-session.lib')
  if not ok then return nil end

  return lib.escaped_session_path_to_session_name(vim.v.this_session)
end

local function open_workspace_names()
  local names = {}
  local seen = {}

  for _, name in ipairs(_G.kickstart_open_workspaces or {}) do
    if name and name ~= '' and not seen[name] then
      table.insert(names, name)
      seen[name] = true
    end
  end

  local current = current_workspace_name()
  if current and not seen[current] then table.insert(names, current) end

  return names
end

local function auto_session_workspaces()
  local ok_auto, auto_session = pcall(require, 'auto-session')
  local ok_lib, lib = pcall(require, 'auto-session.lib')
  if not ok_auto or not ok_lib then return '' end

  local sessions = lib.get_session_list(auto_session.get_root_dir())
  sessions = vim.tbl_filter(function(session) return not is_branch_workspace(session) end, sessions)
  sort_workspaces_by_saved_order(sessions)

  local session_by_name = {}
  for _, session in ipairs(sessions) do
    session_by_name[session.session_name] = session
  end

  local open_names = open_workspace_names()
  if vim.tbl_isempty(open_names) then return '' end

  local current = current_workspace_name()
  local parts = {}

  local reset_hl = vim.g.colors_name and ('%#lualine_y_normal#') or '%*'

  local pruned_open_names = {}
  for index, session_name in ipairs(open_names) do
    local session = session_by_name[session_name] or { session_name = session_name, display_name = session_name }
    local name = index .. ':' .. workspace_display_name(session)
    if name ~= '' then
      if session.session_name == current then
        table.insert(parts, '%#LualineWorkspaceActive# ' .. name .. ' ' .. reset_hl)
      else
        table.insert(parts, ' ' .. name .. ' ')
      end

      if session_by_name[session_name] or session_name == current then table.insert(pruned_open_names, session_name) end
    end
  end

  _G.kickstart_open_workspaces = pruned_open_names

  return table.concat(parts, '')
end

local function parse_org_clock_start(line)
  local year, month, day, hour, min = line:match 'CLOCK:%s*%[(%d%d%d%d)%-(%d%d)%-(%d%d)%s+%a+%s+(%d%d):(%d%d)%]%s*%-%-%s*$'
  if not year then year, month, day, hour, min = line:match 'CLOCK:%s*%[(%d%d%d%d)%-(%d%d)%-(%d%d)%s+%a+%s+(%d%d):(%d%d)%]%s*$' end
  if not year then return end

  return os.time {
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
  }
end

local function find_clock_headline(lines, clock_lnum)
  for lnum = clock_lnum - 1, 1, -1 do
    local headline = lines[lnum] and lines[lnum]:match '^%*+%s+(.+)$'
    if headline then
      return headline:gsub('^%u+%s+', ''):gsub('%s+', ' ')
    end
  end
end

local function find_open_org_clock()
  local function scan_lines(lines)
    for lnum, line in ipairs(lines) do
      local started_at = parse_org_clock_start(line)
      if started_at then
        return {
          started_at = started_at,
          headline = find_clock_headline(lines, lnum),
        }
      end
    end
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if vim.api.nvim_buf_is_loaded(bufnr) and name:match '%.org$' then
      local clock = scan_lines(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
      if clock then return clock end
    end
  end

  for _, file in ipairs(vim.fn.globpath(org_dir, '**/*.org', false, true)) do
    local clock = scan_lines(vim.fn.readfile(file))
    if clock then return clock end
  end
end

local function org_clock_status()
  if _G.orgmode and type(_G.orgmode.statusline) == 'function' then
    local ok, status = pcall(_G.orgmode.statusline)
    if ok and status and status ~= '' then return status end
  end

  local clock = find_open_org_clock()
  if not clock then return '' end

  local elapsed = math.max(0, os.time() - clock.started_at)
  local hours = math.floor(elapsed / 3600)
  local mins = math.floor((elapsed % 3600) / 60)
  local headline = clock.headline and clock.headline ~= '' and (' ' .. clock.headline) or ''
  return ('CLOCK %02d:%02d%s'):format(hours, mins, headline)
end

local function apply_workspace_highlights()
  vim.api.nvim_set_hl(0, 'LualineWorkspaceActive', { fg = '#282c34', bg = '#61afef', bold = true })
end

apply_workspace_highlights()

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('kickstart_lualine_workspace_highlights', { clear = true }),
  callback = apply_workspace_highlights,
})

require('lualine').setup {
  options = {
    theme = 'onedark',
    icons_enabled = vim.g.have_nerd_font,
    globalstatus = true,
    component_separators = '',
    section_separators = '',
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = {
      'branch',
      'diff',
      {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        symbols = {
          error = 'E:',
          warn = 'W:',
          info = 'I:',
          hint = 'H:',
        },
      },
    },
    lualine_c = {
      {
        'filename',
        path = 1,
        shorting_target = 40,
      },
    },
    lualine_x = { org_clock_status },
    lualine_y = { { auto_session_workspaces, padding = { left = 1, right = 0 } } },
    lualine_z = { 'location' },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {
      {
        'filename',
        path = 1,
      },
    },
    lualine_x = { 'location' },
    lualine_y = { 'progress' },
    lualine_z = {},
  },
}
