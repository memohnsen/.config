local M = {}

local open_states = {
  TODO = true,
  PROGRESS = true,
  WAIT = true,
}

local context_tags = {
  h2f = true,
  home = true,
  meetcal = true,
  pg = true,
  wso = true,
}

local project_tags = {
  oss = true,
}

local function trim(text) return vim.trim(text or '') end

local function normalize_title(text)
  text = text:lower()
  text = text:gsub('&', ' and ')
  text = text:gsub('https?://%S+', '')
  text = text:gsub('[^%w]+', ' ')
  return trim(text:gsub('%s+', ' '))
end

local function task_key(line)
  line = line:gsub('^x%s+', '')
  line = line:gsub('^%([A-Z]%)%s+', '')
  line = line:gsub('^%d%d%d%d%-%d%d%-%d%d%s+', '')
  line = line:gsub('%s+[+@][%w_-]+', '')
  line = line:gsub('%s+%w+:%S+', '')
  return normalize_title(line)
end

local function titles_match(left, right)
  if left == '' or right == '' then return false end
  if left == right then return true end

  local shorter, longer = left, right
  if #shorter > #longer then
    shorter, longer = longer, shorter
  end

  return #shorter >= 8 and longer:find(shorter, 1, true) ~= nil and (#longer - #shorter) <= 3
end

local function parse_headline(line)
  local state, rest = line:match '^%s*%*+%s+(%u+)%s+(.+)$'
  if not open_states[state] then return end

  local tags = {}
  local tag_text = rest:match '%s+(:[%w_@#%%:]+:)%s*$'
  if tag_text then
    rest = rest:sub(1, #rest - #tag_text)
    for tag in tag_text:gmatch ':([^:]+)' do
      tags[#tags + 1] = tag:lower()
    end
  end

  local priority = rest:match '%[#([A-Z])%]'
  rest = rest:gsub('%s*%[#%u%]%s*', ' ')

  return {
    priority = priority,
    state = state,
    tags = tags,
    title = trim(rest:gsub('%s+', ' ')),
    body = {},
  }
end

local function collect_task_metadata(task)
  for _, line in ipairs(task.body) do
    local date, repeater = line:match '%f[%u][DS][A-Z]+:%s*<(%d%d%d%d%-%d%d%-%d%d)[^>]*%s([%.+]*%+%d+[hdwmy])[^>]*>'
    if date then
      task.due = task.due or date
      task.repeater = task.repeater or repeater
    else
      task.due = task.due or line:match '%f[%u][DS][A-Z]+:%s*<(%d%d%d%d%-%d%d%-%d%d)'
    end

    if not task.created then
      local created = line:match '^%s*%[(%d%d%d%d%-%d%d%-%d%d)%s+%a%a%a%]%s*$'
      if created then task.created = created end
    end
  end
end

local function parse_org_tasks(lines)
  local tasks = {}
  local current

  for _, line in ipairs(lines) do
    if line:match '^%s*%*+%s+' then
      current = parse_headline(line)
      if current then tasks[#tasks + 1] = current end
    elseif current then
      current.body[#current.body + 1] = line
    end
  end

  for _, task in ipairs(tasks) do
    collect_task_metadata(task)
  end

  return tasks
end

local function render_todo(task)
  local parts = {}
  if task.priority then parts[#parts + 1] = '(' .. task.priority .. ')' end
  if task.created then parts[#parts + 1] = task.created end
  parts[#parts + 1] = task.title

  for _, tag in ipairs(task.tags) do
    if context_tags[tag] then parts[#parts + 1] = '@' .. tag end
  end

  for _, tag in ipairs(task.tags) do
    if project_tags[tag] then parts[#parts + 1] = '+' .. tag end
  end

  if task.due then parts[#parts + 1] = 'due:' .. task.due end
  if task.repeater then parts[#parts + 1] = 'rec:' .. task.repeater end

  return table.concat(parts, ' ')
end

local function read_lines(path)
  if vim.fn.filereadable(path) ~= 1 then return {} end
  return vim.fn.readfile(path)
end

function M.sync(opts)
  opts = opts or {}

  local org_file = vim.fn.expand(opts.org_file or '~/dev/org/todo.org')
  local todo_file = vim.fn.expand(opts.todo_file or '~/dev/org/tuxedo/todo.txt')

  if vim.fn.filereadable(org_file) ~= 1 then return 0 end

  local todo_lines = read_lines(todo_file)
  local existing_keys = {}
  for _, line in ipairs(todo_lines) do
    local key = task_key(line)
    if key ~= '' then existing_keys[#existing_keys + 1] = key end
  end

  local additions = {}
  for _, task in ipairs(parse_org_tasks(read_lines(org_file))) do
    local rendered = render_todo(task)
    local key = task_key(rendered)
    local exists = vim.iter(existing_keys):any(function(existing) return titles_match(existing, key) end)
    if not exists then
      additions[#additions + 1] = rendered
      existing_keys[#existing_keys + 1] = key
    end
  end

  if #additions == 0 then return 0 end

  vim.fn.mkdir(vim.fn.fnamemodify(todo_file, ':h'), 'p')
  vim.list_extend(todo_lines, additions)
  vim.fn.writefile(todo_lines, todo_file)
  return #additions
end

return M
