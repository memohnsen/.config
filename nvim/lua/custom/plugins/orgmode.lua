local gh = function(repo) return 'https://github.com/' .. repo end

local org_dir = vim.fn.expand '~/dev/org'
local daily_dir = org_dir .. '/daily'

local tuxedo_sync_started = false

local image_exts = { png = true, jpg = true, jpeg = true, gif = true, bmp = true, webp = true, svg = true, tiff = true, heic = true, avif = true }

-- True when the current line contains an org image link, e.g.
-- [[file:~/a.png]] or [[./b.jpg][caption]].
local function line_has_image_link(line)
  local target = line:match '%[%[(.-)%]'
  if not target then return false end
  local ext = target:lower():match '%.(%a+)$'
  return ext ~= nil and image_exts[ext] == true
end

local function complete_todo_or_enter()
  local line = vim.api.nvim_get_current_line()

  if line:match '^%s*%*+%s+%u+%s+' then
    require('orgmode').action 'org_mappings.todo_next_state'
    return
  end

  if line:match '^%s*[-+*]%s+%[.%]' then
    require('orgmode').action 'org_mappings.toggle_checkbox'
    return
  end

  if line_has_image_link(line) then
    -- Pop a floating preview of the image at the cursor; move to close.
    Snacks.image.hover()
    return
  end

  vim.cmd.normal { 'j', bang = true }
end

local function find_current_headline()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  for lnum = row, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
    if line and line:match '^%*+%s+' then return lnum, line end
  end
end

local function org_today(repeater) return os.date('<%Y-%m-%d %a ' .. repeater .. '>') end

local function add_repeater_to_timestamp(timestamp, repeater)
  local inner = timestamp:gsub('%s+%.?%+%+?%d+[hdwmy]', '')
  return '<' .. inner .. ' ' .. repeater .. '>'
end

local function normalize_repeater(repeater)
  repeater = vim.trim(repeater or ''):lower()
  if repeater:match '^%.?%+%+?%d+[hdwmy]$' then return repeater end
end

local function make_recurring_todo(repeater)
  repeater = normalize_repeater(repeater)
  if not repeater then
    vim.notify('Use a repeater like +1d, +1w, +1m, .+1w, or ++1w', vim.log.levels.WARN)
    return
  end

  local heading_lnum, heading = find_current_headline()
  if not heading_lnum then
    vim.notify('No org heading found', vim.log.levels.WARN)
    return
  end

  if heading:match '^%*+%s+DONE%s+' then
    heading = heading:gsub('^(%*+%s+)DONE(%s+)', '%1TODO%2', 1)
  elseif not heading:match '^%*+%s+TODO%s+' then
    heading = heading:gsub('^(%*+%s+)', '%1TODO ', 1)
  end
  vim.api.nvim_buf_set_lines(0, heading_lnum - 1, heading_lnum, false, { heading })

  local line_count = vim.api.nvim_buf_line_count(0)
  local next_heading_lnum = line_count + 1
  for lnum = heading_lnum + 1, line_count do
    local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ''
    if line:match '^%*+%s+' then
      next_heading_lnum = lnum
      break
    end
  end

  for lnum = heading_lnum + 1, next_heading_lnum - 1 do
    local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ''
    if line:match 'SCHEDULED:%s*<[^>]+>' then
      local updated = line:gsub(
        'SCHEDULED:%s*(<[^>]+>)',
        function(timestamp) return 'SCHEDULED: ' .. add_repeater_to_timestamp(timestamp:sub(2, -2), repeater) end,
        1
      )
      vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { updated })
      return
    end
  end

  vim.api.nvim_buf_set_lines(0, heading_lnum, heading_lnum, false, { 'SCHEDULED: ' .. org_today(repeater) })
end

local function prompt_recurring_todo()
  local choices = {
    { label = 'Daily (+1d)', value = '+1d' },
    { label = 'Weekly (+1w)', value = '+1w' },
    { label = 'Monthly (+1m)', value = '+1m' },
    { label = 'Yearly (+1y)', value = '+1y' },
    { label = 'Custom', value = 'custom' },
  }

  vim.ui.select(choices, {
    prompt = 'Repeat',
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    if choice.value ~= 'custom' then
      make_recurring_todo(choice.value)
      return
    end

    vim.ui.input({ prompt = 'Repeater (+1d, +1w, .+1w, ++1w): ' }, make_recurring_todo)
  end)
end

local function get_task_date(lines)
  for _, line in ipairs(lines) do
    local date = line:match '%f[%u]DEADLINE:%s*<(%d%d%d%d%-%d%d%-%d%d)' or line:match '%f[%u]SCHEDULED:%s*<(%d%d%d%d%-%d%d%-%d%d)'
    if date then return date end
  end
end

local function sort_todo_file_by_date(bufnr)
  if vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':p') ~= vim.fn.fnamemodify(org_dir .. '/todo.org', ':p') then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local preamble = {}
  local tasks = {}
  local current_task

  for _, line in ipairs(lines) do
    if line:match '^%*%s+' then
      current_task = { lines = { line }, index = #tasks + 1 }
      table.insert(tasks, current_task)
    elseif current_task then
      table.insert(current_task.lines, line)
    else
      table.insert(preamble, line)
    end
  end

  if #tasks < 2 then return end

  for _, task in ipairs(tasks) do
    task.date = get_task_date(task.lines)
  end

  table.sort(tasks, function(left, right)
    if left.date and right.date and left.date ~= right.date then return left.date < right.date end
    if left.date ~= right.date then return left.date ~= nil end
    return left.index < right.index
  end)

  local sorted_lines = vim.list_extend({}, preamble)
  for _, task in ipairs(tasks) do
    vim.list_extend(sorted_lines, task.lines)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, sorted_lines)
end

local function is_open_clock_line(line) return line:match '^%s*CLOCK:%s*%[[^%]]+%]%s*%-%-%s*$' or line:match '^%s*CLOCK:%s*%[[^%]]+%]%s*$' end

local function open_clock_location()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if vim.api.nvim_buf_is_loaded(bufnr) and name:match '%.org$' then
      for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        if is_open_clock_line(line) then return ('%s:%d'):format(name, lnum) end
      end
    end
  end

  for _, file in ipairs(vim.fn.globpath(org_dir, '**/*.org', false, true)) do
    for lnum, line in ipairs(vim.fn.readfile(file)) do
      if is_open_clock_line(line) then return ('%s:%d'):format(file, lnum) end
    end
  end
end

function _G.kickstart_org_active_clock_message()
  local location = open_clock_location()
  if location then return ('Active org clock at %s. Clock out before quitting.'):format(location) end
end

function _G.kickstart_org_block_quit_if_clocked()
  local message = _G.kickstart_org_active_clock_message()
  if message then error(message, 0) end
end

local function setup_daily_todos_in_agenda()
  local agenda_type = require 'orgmode.agenda.types.agenda'
  if agenda_type.mm_daily_todos_enabled then return end

  local original_get_agenda_days = agenda_type._get_agenda_days
  agenda_type._get_agenda_days = function(self)
    local agenda_days = original_get_agenda_days(self)

    for _, agenda_day in ipairs(agenda_days) do
      local file = vim.fn.resolve(vim.fn.fnamemodify(daily_dir .. '/' .. agenda_day.day:format '%Y-%m-%d' .. '.org', ':p'))
      if vim.fn.filereadable(file) == 1 then
        local orgfile = self.files:load_file_sync(file)
        if orgfile then
          for _, headline in ipairs(orgfile:get_unfinished_todo_entries()) do
            local already_visible = vim.iter(agenda_day.agenda_items):any(function(item) return item.headline and headline:is_same(item.headline) end)

            if not already_visible and self:_matches_filters(headline) then
              table.insert(agenda_day.agenda_items, {
                index = #agenda_day.agenda_items + 1,
                headline = headline,
                real_date = agenda_day.day,
                is_day_match = true,
                label = 'Todo:',
                get_hlgroup = function() return nil end,
                get_todo_hlgroup = function() return nil end,
                get_priority_hlgroup = function() return nil end,
              })
              agenda_day.category_length = math.max(agenda_day.category_length, vim.api.nvim_strwidth(headline:get_category()) + 1)
              agenda_day.label_length = math.max(agenda_day.label_length, 5)
            end
          end

          agenda_day.agenda_items = self:_sort(agenda_day.agenda_items)
        end
      end
    end

    return agenda_days
  end

  agenda_type.mm_daily_todos_enabled = true
end

-- doom-one palette (matches Doom Emacs' default theme).
local doom = {
  bg = '#282c34',
  base3 = '#23272e', -- org-block background
  base4 = '#3f444a',
  grey = '#5B6268', -- base5: comments, tags, inactive timestamps
  fg = '#bbc2cf',
  red = '#ff6c6b',
  orange = '#da8548',
  green = '#98be65',
  teal = '#4db5bd',
  yellow = '#ECBE7B',
  blue = '#51afef',
  magenta = '#c678dd',
  violet = '#a9a1e1',
  cyan = '#46D9FF',
}

local function apply_org_headline_colors()
  local hl = function(group, val) vim.api.nvim_set_hl(0, group, val) end

  -- Headline levels (rotating colors, bold), like Doom's org-level faces.
  local levels = {
    doom.blue,
    doom.magenta,
    doom.green,
    doom.orange,
    doom.cyan,
    doom.violet,
    doom.yellow,
    doom.grey,
  }
  for level, color in ipairs(levels) do
    hl('@org.headline.level' .. level, { fg = color, bold = true })
  end

  -- Source/example blocks: subtle tinted background like doom-themes-org-config.
  hl('@org.block', { bg = doom.base3 })
  hl('OrgBlock', { bg = doom.base3 })
  hl('@org.block.background', { bg = doom.base3 })
  hl('OrgBlockTangleInfo', { fg = doom.grey, bg = doom.base3 })

  -- Inline markup.
  hl('@org.code', { fg = doom.orange }) -- ~code~
  hl('@org.verbatim', { fg = doom.green }) -- =verbatim=
  hl('OrgEmphasisBold', { bold = true })
  hl('OrgEmphasisItalic', { italic = true })
  hl('OrgEmphasisUnderline', { underline = true })
  hl('OrgEmphasisStrikethrough', { strikethrough = true })

  -- Tables.
  hl('@org.table', { fg = doom.blue })
  hl('@org.table.heading', { fg = doom.blue, bold = true })
  hl('@org.table.delimiter', { fg = doom.base4 })

  -- Checkboxes.
  hl('@org.checkbox', { fg = doom.grey })
  hl('@org.checkbox.checked', { fg = doom.green })
  hl('@org.checkbox.halfchecked', { fg = doom.yellow })
  hl('@org.checkbox.done', { fg = doom.grey }) -- muted text for completed [X] items

  -- Tags, links, timestamps.
  hl('@org.tag', { fg = doom.grey, italic = true })
  hl('@org.hyperlink', { fg = doom.blue, underline = true })
  hl('OrgLink', { fg = doom.blue, underline = true })
  hl('@org.timestamp.active', { fg = doom.blue })
  hl('@org.timestamp.inactive', { fg = doom.grey })

  -- Priorities ([#A] / [#B] / [#C]).
  hl('@org.priority.highest', { fg = doom.red, bold = true })
  hl('@org.priority.high', { fg = doom.orange, bold = true })
  hl('@org.priority.default', { fg = doom.yellow })
  hl('@org.priority.low', { fg = doom.green })
  hl('@org.priority.lowest', { fg = doom.grey })
end

local function run_command(command, opts)
  opts = opts or {}

  if vim.system then
    local result = vim.system(command, { cwd = opts.cwd, text = true }):wait()
    return result.code == 0, (result.stdout or '') .. (result.stderr or '')
  end

  local previous_cwd
  if opts.cwd then
    previous_cwd = vim.fn.getcwd()
    vim.cmd.cd(vim.fn.fnameescape(opts.cwd))
  end

  local output = vim.fn.system(command)
  local ok = vim.v.shell_error == 0

  if previous_cwd then vim.cmd.cd(vim.fn.fnameescape(previous_cwd)) end

  return ok, output
end

local function sync_org_tasks_to_tuxedo()
  local ok, added = pcall(require('custom.org_tuxedo_sync').sync, {
    org_file = org_dir .. '/todo.org',
    todo_file = org_dir .. '/tuxedo/todo.txt',
  })

  if not ok then
    vim.notify('Tuxedo todo sync failed: ' .. added, vim.log.levels.ERROR)
    return
  end

  if added > 0 then vim.notify(('Synced %d org task%s to Tuxedo'):format(added, added == 1 and '' or 's'), vim.log.levels.INFO) end
end

local function sync_org_tasks_to_tuxedo_once()
  if tuxedo_sync_started then return end
  tuxedo_sync_started = true
  sync_org_tasks_to_tuxedo()
end

local function archive_done_org_tasks(bufnr)
  local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':p')
  if file ~= vim.fn.fnamemodify(org_dir .. '/todo.org', ':p') then return end

  local script = doom_dir .. '/scripts/archive-done-org-tasks'
  if vim.fn.executable(script) ~= 1 then return end

  local ok, output = run_command { script, org_dir }
  if ok then
    vim.cmd.edit { bang = true }
    vim.notify('Archived completed non-recurring tasks from todo.org', vim.log.levels.INFO)
  else
    vim.notify('Done task archive failed' .. (output ~= '' and (': ' .. vim.trim(output)) or ''), vim.log.levels.ERROR)
  end
end

local function org_git_root()
  if vim.fn.isdirectory(org_dir) ~= 1 then return end

  local ok, output = run_command({ 'git', 'rev-parse', '--show-toplevel' }, { cwd = org_dir })
  if ok then return vim.trim(output) end
end

local function save_org_buffers()
  local org_root = vim.fn.fnamemodify(org_dir, ':p')
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local file = vim.api.nvim_buf_get_name(bufnr)
    if file ~= '' and vim.bo[bufnr].modified and vim.startswith(vim.fn.fnamemodify(file, ':p'), org_root) then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd.write() end)
    end
  end
end

local function git_commit_and_push_org_dir()
  local root = org_git_root()
  if not root then
    vim.notify('Org directory is not inside a Git repo: ' .. org_dir, vim.log.levels.WARN)
    return
  end

  save_org_buffers()

  local status_ok, status = run_command({ 'git', 'status', '--porcelain' }, { cwd = root })
  if not status_ok then
    vim.notify('Org directory Git status failed', vim.log.levels.ERROR)
    return
  end

  if vim.trim(status) ~= '' then
    local add_ok = run_command({ 'git', 'add', '-A' }, { cwd = root })
    if not add_ok then
      vim.notify('Org directory Git add failed', vim.log.levels.ERROR)
      return
    end

    local commit_ok = run_command({ 'git', 'commit', '-m', os.date 'Update org files %Y-%m-%d %H:%M' }, { cwd = root })
    if not commit_ok then
      vim.notify('Org directory Git commit failed', vim.log.levels.ERROR)
      return
    end
  end

  local push_ok = run_command({ 'git', 'push' }, { cwd = root })
  if not push_ok then vim.notify('Org directory Git push failed', vim.log.levels.ERROR) end
end

local opts = {
  org_agenda_files = org_dir .. '/**/*.org',
  org_default_notes_file = org_dir .. '/notes.org',
  org_deadline_warning_days = 0,
  org_startup_folded = 'showeverything',
  org_todo_keywords = { 'TODO(t)', 'PROGRESS(p)', 'WAIT(w)', '|', 'DONE(d)' },

  -- Doom Emacs look-and-feel.
  org_startup_indented = true, -- org-indent-mode: virtually indent subtrees under their heading
  org_hide_emphasis_markers = true, -- show *bold* / /italic/ rendered, hide the markers
  org_ellipsis = ' ▾', -- Doom's `org-ellipsis " ▾"` fold indicator
  org_todo_keyword_faces = {
    TODO = ':foreground #ff6c6b :weight bold', -- doom-one red
    PROGRESS = ':foreground #da8548 :weight bold', -- doom-one orange
    WAIT = ':foreground #ECBE7B :weight bold', -- doom-one yellow
    DONE = ':foreground #98be65 :weight bold', -- doom-one green
  },
  mappings = {
    global = {
      org_agenda = false,
    },
    org = {
      -- Task dates
      org_deadline = { '<leader>od', desc = 'Deadline' },
      org_schedule = { '<leader>os', desc = 'Schedule' },

      -- Task metadata
      org_priority = { '<leader>op', desc = 'Priority' },

      -- Headings
      org_set_tags_command = { '<leader>ot', desc = 'Tags' },

      -- Source/export
      org_export = { '<leader>oe', desc = 'Export' },

      -- Clocking
      org_clock_goto = { '<leader>oxg', desc = 'Go to Active Clock' },

      -- Disabled defaults that were cluttering <leader>o.
      org_add_note = false,
      org_archive_subtree = false,
      org_babel_tangle = false,
      org_edit_special = false,
      org_insert_heading_respect_content = false,
      org_insert_link = false,
      org_insert_todo_heading = false,
      org_insert_todo_heading_respect_content = false,
      org_meta_return = false,
      org_move_subtree_down = false,
      org_move_subtree_up = false,
      org_open_at_point = false,
      org_refile = false,
      org_set_effort = false,
      org_time_stamp = false,
      org_time_stamp_inactive = false,
      org_toggle_archive_tag = false,
      org_toggle_timestamp_type = false,
      org_toggle_heading = false,
      org_store_link = false,
    },
    agenda = {
      -- Task dates
      org_agenda_schedule = { '<leader>os', desc = 'Schedule' },

      -- Task metadata
      org_agenda_deadline = { '<leader>od', desc = 'Deadline' },
      org_agenda_priority = { '<leader>op', desc = 'Priority' },
      org_agenda_set_tags = { '<leader>ot', desc = 'Tags' },

      -- Disabled defaults that were cluttering <leader>o.
      org_agenda_add_note = false,
      org_agenda_archive = false,
      org_agenda_open_at_point = false,
      org_agenda_refile = false,
      org_agenda_toggle_archive_tag = false,
    },
  },
  org_capture_templates = {
    t = {
      description = 'Task',
      template = '* TODO %?\n  %u',
      target = org_dir .. '/todo.org',
    },
    n = {
      description = 'Note',
      template = '* %?\n  %u',
      target = org_dir .. '/notes.org',
    },
    d = {
      description = 'Daily log',
      template = '* %<%H:%M> %?',
      target = daily_dir .. '/%<%Y-%m-%d>.org',
    },
  },
}

vim.keymap.set('n', '<leader>oc', '<cmd>Org capture<cr>', { desc = 'Org Capture' })

vim.api.nvim_create_user_command('OrgTuxedoSync', sync_org_tasks_to_tuxedo, { desc = 'Sync org tasks to Tuxedo todo.txt' })

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('kickstart_org_keymaps', { clear = true }),
  pattern = 'org',
  callback = function(event)
    -- Keep agenda buffers on orgmode's default <CR> behavior.
    -- This custom mapping is only for actual .org files.
    local bufname = vim.api.nvim_buf_get_name(event.buf)
    if vim.bo[event.buf].buftype ~= '' or not bufname:match '%.org$' then return end

    vim.keymap.set('n', '<CR>', complete_todo_or_enter, { buffer = event.buf, desc = 'Complete TODO or Enter' })
    vim.keymap.set('n', '<leader>or', prompt_recurring_todo, { buffer = event.buf, desc = 'Make TODO Recurring' })
    pcall(
      function()
        require('which-key').add({
          { '<leader>o', group = 'Org' },
          { '<leader>od', desc = 'Deadline' },
          { '<leader>os', desc = 'Schedule' },
          { '<leader>or', desc = 'Make TODO Recurring' },
          { '<leader>op', desc = 'Priority' },
          { '<leader>ot', desc = 'Tags' },
          { '<leader>oe', desc = 'Export' },
          { '<leader>ox', group = 'Clock' },
          { '<leader>oxg', desc = 'Go to Active Clock' },
        }, { buffer = event.buf })
      end
    )
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('kickstart_org_todo_sort', { clear = true }),
  pattern = org_dir .. '/todo.org',
  callback = function(event) sort_todo_file_by_date(event.buf) end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('kickstart_org_archive_done', { clear = true }),
  pattern = org_dir .. '/todo.org',
  callback = function(event) archive_done_org_tasks(event.buf) end,
})

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('kickstart_org_tuxedo_sync', { clear = true }),
  callback = function()
    if vim.tbl_isempty(vim.api.nvim_list_uis()) then return end
    vim.defer_fn(sync_org_tasks_to_tuxedo_once, 1000)
  end,
})

vim.api.nvim_create_autocmd('VimLeavePre', {
  group = vim.api.nvim_create_augroup('kickstart_org_git_commit_push', { clear = true }),
  callback = function()
    if vim.tbl_isempty(vim.api.nvim_list_uis()) then return end
    git_commit_and_push_org_dir()
  end,
})

vim.api.nvim_create_autocmd('QuitPre', {
  group = vim.api.nvim_create_augroup('kickstart_org_clock_quit_guard', { clear = true }),
  callback = function()
    if vim.tbl_isempty(vim.api.nvim_list_uis()) then return end
    _G.kickstart_org_block_quit_if_clocked()
  end,
})

vim.pack.add { gh 'nvim-orgmode/orgmode' }

local ts_install = require 'orgmode.utils.treesitter.install'
local version = ts_install.get_version_info()
if version.installed and not version.installed_in_orgmode_dir then
  for _, parser in ipairs(version.parser_locations) do
    os.remove(parser)
  end
  require('orgmode.config'):install_grammar()
elseif version.version_mismatch or version.outdated then
  require('orgmode.config'):reinstall_grammar()
end

require('orgmode').setup(opts)

-- org-superstar equivalent: replace the leading stars with fancy bullets and
-- prettify checkboxes, matching Doom's default org appearance.
vim.pack.add { gh 'nvim-orgmode/org-bullets.nvim' }
require('org-bullets').setup {
  concealcursor = false,
  symbols = {
    headlines = { '◉', '○', '✸', '✿' },
    -- Checkboxes are handled by a treesitter conceal in queries/org/highlights.scm
    -- instead, so the whole `[ ]` is replaced by a single glyph (org-bullets only
    -- swaps the inner character and keeps the brackets).
    checkboxes = false,
  },
}

apply_org_headline_colors()

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('kickstart_org_headline_colors', { clear = true }),
  callback = function() apply_org_headline_colors() end,
})
