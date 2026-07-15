local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')
local modules = {}

for file_name, type in vim.fs.dir(plugins_dir) do
  if type == 'file' and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    local module = file_name:gsub('%.lua$', '')
    table.insert(modules, module)
  end
end

table.sort(modules)
local specs = {}
for _, module in ipairs(modules) do
  if module ~= 'keymaps' then vim.list_extend(specs, require('custom.plugins.' .. module)) end
end

return specs
