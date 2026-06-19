local M = {}

local global_bp_config = vim.fn.stdpath('config') .. '/basedpyright.json'

local function python_path(root_dir)
  for _, path in ipairs({
    root_dir .. '/.venv/bin/python',
    root_dir .. '/venv/bin/python',
  }) do
    if vim.uv.fs_stat(path) then
      return path
    end
  end
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. '/bin/python'
  end
  return nil
end

function M.settings(root_dir)
  local analysis = {
    typeCheckingMode = 'off',
    configFilePath = global_bp_config,
    autoSearchPaths = true,
    diagnosticMode = 'openFilesOnly',
    extraPaths = { root_dir, root_dir .. '/src' },
    inlayHints = {
      variableTypes = false,
      callArgumentNames = false,
      callArgumentNamesMatching = false,
      functionReturnTypes = false,
      genericTypes = false,
    },
  }

  local settings = {
    basedpyright = { analysis = analysis },
  }

  local path = python_path(root_dir)
  if path then
    settings.python = { pythonPath = path }
  end

  return settings
end

function M.push_settings(client)
  if client.name ~= 'basedpyright' then
    return
  end
  local root_dir = client.root_dir or vim.fn.getcwd()
  local settings = M.settings(root_dir)
  client.settings = vim.tbl_deep_extend('force', client.settings or {}, settings)
  client:notify('workspace/didChangeConfiguration', { settings = settings })
end

return M
