local M = {}

local configured = false
local last_error

local function remove_nix_paths()
  local paths = {}
  for entry in vim.gsplit(vim.env.PATH or '', ':', { plain = true }) do
    if not vim.startswith(entry, '/nix/') and not vim.startswith(entry, vim.fn.expand '~/.nix-profile/') then
      paths[#paths + 1] = entry
    end
  end
  vim.env.PATH = table.concat(paths, ':')
  vim.env.NIX_PROFILES = nil
  vim.env.NIX_PATH = nil
  vim.env.NIX_SSL_CERT_FILE = nil
end
-- Keep Neovim's original temporary directory when a project environment
-- changes variables, so Zellij's session socket remains reachable.
local preserved_temp_vars = {
  TMPDIR = vim.env.TMPDIR,
  TMP = vim.env.TMP,
  TEMP = vim.env.TEMP,
  TEMPDIR = vim.env.TEMPDIR,
}

local function notify_error(cwd, message)
  local error_key = cwd .. '\n' .. message
  if last_error == error_key then return end

  last_error = error_key
  vim.notify(('direnv failed for %s:\n%s'):format(cwd, message), vim.log.levels.ERROR)
end

local function apply_environment(environment)
  local changed = false

  for name, value in pairs(environment) do
    if value == vim.NIL then value = nil end
    if value ~= nil then value = tostring(value) end

    if vim.env[name] ~= value then
      vim.env[name] = value
      changed = true
    end
  end

  return changed
end

function M.refresh(options)
  options = options or {}
  local executable = vim.fn.exepath 'direnv'
  if executable == '' then
    if not options.silent then notify_error(vim.uv.cwd() or '?', 'executable not found') end
    return false
  end

  local cwd = vim.uv.cwd()
  if not cwd then return false end

  local result = vim.system({ executable, 'export', 'json' }, { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    if not options.silent then
      local message = vim.trim(result.stderr or '')
      notify_error(cwd, message ~= '' and message or ('exit status ' .. result.code))
    end
    return false
  end

  local output = vim.trim(result.stdout or '')
  if output == '' then output = '{}' end

  local ok, environment = pcall(vim.json.decode, output)
  if not ok or type(environment) ~= 'table' then
    if not options.silent then notify_error(cwd, 'invalid JSON response') end
    return false
  end

  last_error = nil
  local changed = apply_environment(environment)
  for name, value in pairs(preserved_temp_vars) do
    if vim.env[name] ~= value then
      vim.env[name] = value
      changed = true
    end
  end
  if changed then vim.api.nvim_exec_autocmds('User', {
    pattern = 'DirenvLoaded',
    modeline = false,
    data = { cwd = cwd },
  }) end

  if options.notify then vim.notify('Loaded direnv environment: ' .. cwd, vim.log.levels.INFO) end
  return changed
end

function M.setup()
  if configured then return end
  configured = true
  remove_nix_paths()

  -- Run before plugins initialize so formatters and language servers inherit
  -- the project environment even when Neovim starts inside a repository.
  M.refresh()

  local group = vim.api.nvim_create_augroup('kickstart-direnv', { clear = true })
  vim.api.nvim_create_autocmd({ 'DirChanged', 'VimEnter' }, {
    group = group,
    callback = function() M.refresh() end,
  })

  vim.api.nvim_create_user_command('DirenvReload', function() M.refresh { notify = true } end, {
    desc = "Reload direnv for Neovim's current working directory",
  })
end

return M
