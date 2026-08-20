local in_zellij = vim.env.ZELLIJ ~= nil

if not in_zellij then
  vim.keymap.set('n', '<A-h>', '<C-w>h', { desc = 'Navigate left', silent = true })
  vim.keymap.set('n', '<A-j>', '<C-w>j', { desc = 'Navigate down', silent = true })
  vim.keymap.set('n', '<A-k>', '<C-w>k', { desc = 'Navigate up', silent = true })
  vim.keymap.set('n', '<A-l>', '<C-w>l', { desc = 'Navigate right', silent = true })
end

local wincmd_for = { left = 'h', down = 'j', up = 'k', right = 'l' }

local cached_session
local cached_system_tmp

local function system_temp_dir()
  if cached_system_tmp ~= nil then return cached_system_tmp end

  local result = vim.system({ '/usr/bin/getconf', 'DARWIN_USER_TEMP_DIR' }, { text = true }):wait()
  local dir = result.code == 0 and vim.trim(result.stdout or '') or ''
  cached_system_tmp = dir ~= '' and dir or false
  return cached_system_tmp
end

local function active_session()
  if cached_session then return cached_session end

  local zellij = vim.fn.exepath 'zellij'
  if zellij == '' then return nil end

  local result = vim.system({ zellij, 'list-sessions', '--no-formatting' }, { text = true }):wait()
  if result.code ~= 0 then return nil end

  local first
  for line in result.stdout:gmatch '[^\r\n]+' do
    local name = line:match '^(%S+)'
    if name and not line:find 'EXITED' then
      if line:find 'current' then
        cached_session = name
        return name
      end
      first = first or name
    end
  end

  cached_session = first
  return first
end

local function spawn_action(zellij, action, direction, session, extra_env)
  local opts = { text = true }
  if extra_env then opts.env = extra_env end
  return vim.system({ zellij, '--session', session, 'action', action, direction }, opts):wait()
end

local function run_action(zellij, action, direction)
  local named = vim.env.ZELLIJ_SESSION_NAME
  if not named or named == '' then named = active_session() end
  if not named then return { code = 1, stderr = 'no active zellij session found' } end

  local result = spawn_action(zellij, action, direction, named, nil)
  if result.code == 0 then
    vim.env.ZELLIJ_SESSION_NAME = named
    return result
  end

  -- Retry against the real system temporary directory and a currently live
  -- session in case a project environment or inherited session name is stale.
  local real_tmp = system_temp_dir()
  local resolved = active_session()

  local seen = { [named] = true }
  local attempts = { { session = named, env = nil } }
  if resolved and not seen[resolved] then
    seen[resolved] = true
    attempts[#attempts + 1] = { session = resolved, env = nil }
  end

  for _, attempt in ipairs(attempts) do
    if real_tmp then
      local r = spawn_action(zellij, action, direction, attempt.session, { TMPDIR = real_tmp })
      if r.code == 0 then
        vim.env.ZELLIJ_SESSION_NAME = attempt.session
        vim.env.TMPDIR = real_tmp
        return r
      end
    end
    if attempt.session ~= named then
      local r = spawn_action(zellij, action, direction, attempt.session, nil)
      if r.code == 0 then
        vim.env.ZELLIJ_SESSION_NAME = attempt.session
        return r
      end
    end
  end

  return result
end

local function navigate(direction)
  local action = (direction == 'left' or direction == 'right') and 'move-focus-or-tab' or 'move-focus'

  local before = vim.fn.winnr()
  vim.api.nvim_command('wincmd ' .. (wincmd_for[direction] or 'w'))
  if vim.fn.winnr() ~= before then return end

  local zellij = vim.fn.exepath 'zellij'
  if zellij == '' then
    vim.notify('zellij-nav: zellij executable not found in PATH', vim.log.levels.WARN)
    return
  end

  local result = run_action(zellij, action, direction)
  if result.code ~= 0 then
    cached_session = nil
    local message = vim.trim(result.stderr ~= '' and result.stderr or (result.stdout or ''))
    vim.notify(
      ('zellij-nav: zellij action %s %s failed (exit %d)'):format(action, direction, result.code)
        .. (message ~= '' and (': ' .. message) or ''),
      vim.log.levels.WARN
    )
  end
end

return {
  {
    'swaits/zellij-nav.nvim',
    cond = in_zellij,
    event = 'VeryLazy',
    keys = {
      { '<A-h>', function() navigate 'left' end, desc = 'Navigate left or tab', silent = true },
      { '<A-j>', function() navigate 'down' end, desc = 'Navigate down', silent = true },
      { '<A-k>', function() navigate 'up' end, desc = 'Navigate up', silent = true },
      { '<A-l>', function() navigate 'right' end, desc = 'Navigate right or tab', silent = true },
    },
    opts = {},
  },
}
