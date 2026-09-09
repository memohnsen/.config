local M = {}

local header_lines = {
  [[                                                                     ]],
  [[       ████ ██████           █████      ██                     ]],
  [[      ███████████             █████                             ]],
  [[      █████████ ███████████████████ ███   ███████████   ]],
  [[     █████████  ███    █████████████ █████ ██████████████   ]],
  [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
  [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
  [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
}

local function header_items()
  local items = {}
  for _, line in ipairs(header_lines) do
    items[#items + 1] = {
      align = 'center',
      text = { { line, hl = 'SnacksDashboardHeader' } },
    }
  end
  return items
end

local function workspace_display_name(session)
  if _G.kickstart_workspaces and _G.kickstart_workspaces.display_name then return _G.kickstart_workspaces.display_name(session) end

  local name = session.display_name or session.session_name or ''
  name = name:gsub('^~/', ''):gsub('^' .. vim.pesc(vim.fn.expand '~') .. '/', '')
  return vim.fn.fnamemodify(name, ':t')
end

local function restore_workspace(session)
  local workspaces = _G.kickstart_workspaces
  if workspaces and workspaces.restore then
    workspaces.restore(session.session_name)
    return
  end

  local ok, auto_session = pcall(require, 'auto-session')
  if ok then auto_session.autosave_and_restore(session.session_name) end
end

local function new_session()
  local workspaces = _G.kickstart_workspaces
  if workspaces and workspaces.new then
    workspaces.new()
    return
  end

  vim.notify('Workspace plugin is not ready yet', vim.log.levels.WARN)
end

local function session_items()
  local items = {
    {
      icon = ' ',
      desc = 'New Session',
      key = 'n',
      action = new_session,
    },
  }

  local sessions = {}
  if _G.kickstart_workspaces and _G.kickstart_workspaces.recent then
    sessions = _G.kickstart_workspaces.recent()
  else
    local ok_auto, auto_session = pcall(require, 'auto-session')
    local ok_lib, lib = pcall(require, 'auto-session.lib')
    if ok_auto and ok_lib then
      sessions = vim.tbl_filter(function(session) return not (session.session_name and session.session_name:find('|', 1, true)) end, lib.get_session_list(auto_session.get_root_dir()))
    end
  end

  for _, session in ipairs(sessions) do
    items[#items + 1] = {
      icon = ' ',
      desc = workspace_display_name(session),
      autokey = true,
      action = function() restore_workspace(session) end,
    }
  end
  return items
end

function M.dashboard()
  return {
    enabled = true,
    width = 70,
    pane_gap = 4,
    preset = {
      header = table.concat(header_lines, '\n'),
    },
    sections = function()
      local items = header_items()
      items[#items + 1] = { padding = 1 }
      items[#items + 1] = {
        align = 'center',
        text = { { 'Sessions', hl = 'SnacksDashboardTitle' } },
        padding = 1,
      }
      vim.list_extend(items, session_items())
      return items
    end,
  }
end

function M.hide_chrome()
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('kickstart_home_chrome', { clear = true }),
    pattern = 'snacks_dashboard',
    callback = function(args)
      vim.opt.showtabline = 0
      vim.opt.laststatus = 0
      vim.opt.cmdheight = 0
      vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufDelete' }, {
        buffer = args.buf,
        once = true,
        callback = function()
          vim.opt.showtabline = 2
          vim.opt.laststatus = 3
          vim.opt.cmdheight = 1
        end,
      })
    end,
  })
end

return M
