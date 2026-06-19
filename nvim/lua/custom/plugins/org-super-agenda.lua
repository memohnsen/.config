local gh = function(repo) return 'https://github.com/' .. repo end

local org_dir = vim.fn.expand '~/dev/org'
local calendar_file = org_dir .. '/calendar.org'
local calendar_event_hl = 'KickstartOrgSuperAgendaCalendarEvent'
local agenda_hl = {
  group = 'KickstartOrgSuperAgendaGroup',
  filename = 'KickstartOrgSuperAgendaFilename',
  date = 'KickstartOrgSuperAgendaDate',
  headline = 'KickstartOrgSuperAgendaHeadline',
  tags = 'KickstartOrgSuperAgendaTags',
  project_default = 'KickstartOrgSuperAgendaProjectDefault',
  priority_a = 'KickstartOrgSuperAgendaPriorityA',
  priority_b = 'KickstartOrgSuperAgendaPriorityB',
  priority_c = 'KickstartOrgSuperAgendaPriorityC',
}
local project_colors = {
  pg = '#C678DD',
  meetcal = '#E06C75',
  oss = '#61AFEF',
  h2f = '#D19A66',
  wso = '#98C379',
}
local state_colors = {
  TODO = '#98C379',
  PROGRESS = '#61AFEF',
  WAIT = '#E5C07B',
  DONE = '#98C379',
}
local state_sort = {
  by = 'todo',
  order = 'asc',
  todo_order = { 'PROGRESS', 'TODO', 'WAIT', 'DONE' },
  secondary = 'date_priority',
}

vim.pack.add { gh 'hamidi-dev/org-super-agenda.nvim' }

local ok_utils, utils = pcall(require, 'org-super-agenda.adapters.neovim.utils')
if ok_utils then utils.get_org_files = function(dir) return vim.fn.globpath(vim.fn.expand(dir), '**/*.org', false, true) end end

local function apply_agenda_highlights()
  vim.api.nvim_set_hl(0, calendar_event_hl, { bg = '#5A3D8A' })
  vim.api.nvim_set_hl(0, agenda_hl.group, { fg = '#C9D1E9', bold = true })
  vim.api.nvim_set_hl(0, agenda_hl.filename, { fg = '#7F848E' })
  vim.api.nvim_set_hl(0, agenda_hl.date, { fg = '#7F848E' })
  vim.api.nvim_set_hl(0, agenda_hl.headline, { fg = '#ABB2BF' })
  vim.api.nvim_set_hl(0, agenda_hl.tags, { fg = '#7F848E' })
  vim.api.nvim_set_hl(0, agenda_hl.project_default, { fg = '#282C34', bg = '#7F848E', bold = true })
  vim.api.nvim_set_hl(0, agenda_hl.priority_a, { fg = '#282C34', bg = '#E06C75', bold = true })
  vim.api.nvim_set_hl(0, agenda_hl.priority_b, { fg = '#282C34', bg = '#E5C07B', bold = true })
  vim.api.nvim_set_hl(0, agenda_hl.priority_c, { fg = '#282C34', bg = '#7F848E', bold = true })
  for project, color in pairs(project_colors) do
    vim.api.nvim_set_hl(0, 'KickstartOrgSuperAgendaProject_' .. project, { fg = '#282C34', bg = color, bold = true })
  end
  vim.api.nvim_set_hl(0, 'OrgSA_TODO', { fg = '#282C34', bg = state_colors.TODO, bold = true })
  vim.api.nvim_set_hl(0, 'OrgSA_PROGRESS', { fg = '#282C34', bg = state_colors.PROGRESS, bold = true })
  vim.api.nvim_set_hl(0, 'OrgSA_WAIT', { fg = '#282C34', bg = state_colors.WAIT, bold = true })
  vim.api.nvim_set_hl(0, 'OrgSA_DONE', { fg = '#7F848E', strikethrough = true })
  vim.api.nvim_set_hl(0, 'OrgSA_Group', { fg = '#C9D1E9', bold = true })
  vim.api.nvim_set_hl(0, 'OrgSA_NONE', { fg = '#ABB2BF' })
  vim.api.nvim_set_hl(0, 'OrgSA_Marked', { fg = '#E5C07B', bold = true })
  vim.api.nvim_set_hl(0, 'OrgSA_Clock', { fg = '#61AFEF', bold = true })
end

local function is_calendar_item(item)
  return item
    and item.file
    and vim.fn.fnamemodify(item.file, ':p') == vim.fn.fnamemodify(calendar_file, ':p')
end

local function setup_calendar_event_row_highlights()
  local layouts = {
    require 'org-super-agenda.core.layout.classic',
    require 'org-super-agenda.core.layout.compact',
  }

  for _, layout in ipairs(layouts) do
    if not layout.kickstart_calendar_event_row_highlight then
      local original_build = layout.build

      layout.build = function(groups, win_width, cfg, marked)
        local rows, hls, line_map = original_build(groups, win_width, cfg, marked)

        for lnum, item in pairs(line_map) do
          if is_calendar_item(item) then
            table.insert(hls, 1, { lnum - 1, 0, -1, calendar_event_hl })
          end
        end

        return rows, hls, line_map
      end

      layout.kickstart_calendar_event_row_highlight = true
    end
  end
end

local function truncate(str, len)
  if not len or #str <= len then return str end
  return str:sub(1, len - 1) .. '…'
end

local function item_key(item)
  return string.format('%s:%s', item.file or '', item._src_line or 0)
end

local function short_date(date)
  if date and date.month and date.day then
    local month = ({ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' })[date.month]
    if month then return string.format('%s %d', month, date.day) end
  end
  return tostring(date or '')
end

local function date_label(item)
  local parts = {}
  if item.deadline then
    local days = item.deadline:days_from_today()
    parts[#parts + 1] = days < 0 and string.format('%dd ago', math.abs(days))
      or days == 0 and 'deadline'
      or ('Due ' .. short_date(item.deadline))
  end
  if item.scheduled then
    local days = item.scheduled:days_from_today()
    parts[#parts + 1] = days < 0 and string.format('Sched. %dx', math.abs(days))
      or days == 0 and 'Scheduled'
      or short_date(item.scheduled)
  end
  return table.concat(parts, '  ')
end

local function priority_hl(priority)
  return ({
    A = agenda_hl.priority_a,
    B = agenda_hl.priority_b,
    C = agenda_hl.priority_c,
  })[priority]
end

local function project_name(item)
  local properties = item.properties or {}
  local project = properties.PROJECT or properties.project
  if project and project ~= '' then return project:lower() end

  for _, tag in ipairs(item.tags or {}) do
    if tag ~= '' then return tag:lower() end
  end
end

local function project_hl(project)
  if not project then return end
  if project_colors[project] then return 'KickstartOrgSuperAgendaProject_' .. project end
  return agenda_hl.project_default
end

local function title_label(label)
  return (label:gsub('^%l', string.upper))
end

local function centered(text, width)
  text = text or ''
  if #text >= width then return text:sub(1, width) end
  local left = math.floor((width - #text) / 2)
  local right = width - #text - left
  return string.rep(' ', left) .. text .. string.rep(' ', right)
end

local function project_label(project)
  return centered(project or '', 9)
end

local function setup_doom_compact_layout()
  local layout = require 'org-super-agenda.core.layout.compact'
  if layout.kickstart_doom_compact_layout then return end

  layout.build = function(groups, win_width, cfg, marked)
    local rows, hls, line_map = {}, {}, {}
    local filename_w = cfg.compact and cfg.compact.filename_min_width or 10
    local label_w = cfg.compact and cfg.compact.label_min_width or 12

    for _, group in ipairs(groups) do
      for _, item in ipairs(group.items) do
        local filename = ((item.file or ''):match '[^/]+$' or ''):gsub('%.org$', '')
        filename_w = math.max(filename_w, #filename + 1)
      end
    end

    local lnum = 0
    local function emit(line)
      lnum = lnum + 1
      rows[lnum] = line
      return lnum
    end

    for _, group in ipairs(groups) do
      if #group.items > 0 then
        if #rows > 0 then emit('') end
        local header_lnum = emit(title_label(group.name))
        line_map[header_lnum] = { _kind = 'group_header', group_name = group.name }
        hls[#hls + 1] = { header_lnum - 1, 0, -1, agenda_hl.group }

        if not group.collapsed then
          for _, item in ipairs(group.items) do
            local filename = (((item.file or ''):match '[^/]+$' or ''):gsub('%.org$', '') .. ':')
            local label = date_label(item)
            local todo = item.todo_state or ''
            local priority = (item.priority and item.priority ~= '') and ('#' .. item.priority) or ''
            local project = project_name(item)
            local show_project = not is_calendar_item(item)
            local marked_prefix = marked and marked[item_key(item)] and '● ' or '  '
            local clock_prefix = item.clocked_in and '⏱ ' or ''

            local text = marked_prefix .. clock_prefix
            local spans = {}
            local filename_start = #text
            text = text .. string.format('%-' .. filename_w .. 's', filename)
            spans[#spans + 1] = { field = 'filename', s = filename_start, e = #text, hl = agenda_hl.filename }

            local label_start = #text
            text = text .. string.format('%-' .. label_w .. 's', label)
            spans[#spans + 1] = { field = 'date', s = label_start, e = #text, hl = agenda_hl.date }

            text = text .. ' '
            local todo_start = #text
            text = text .. centered(todo, 10)
            spans[#spans + 1] = { field = 'todo', s = todo_start, e = #text, hl = 'OrgSA_' .. todo }

            if priority ~= '' then
              text = text .. ' '
              local priority_start = #text
              text = text .. ' ' .. priority .. ' '
              spans[#spans + 1] = { field = 'priority', s = priority_start, e = #text, hl = priority_hl(item.priority) }
            end

            if show_project then
              text = text .. ' '
              local project_start = #text
              text = text .. project_label(project)
              spans[#spans + 1] = { field = 'project', s = project_start, e = #text, hl = project_hl(project) or agenda_hl.project_default }
            end

            text = text .. ' '
            local headline_start = #text
            text = text .. truncate(item.headline or '', cfg.heading_max_length)
            if item.has_more then text = text .. ' …' end
            spans[#spans + 1] = { field = 'headline', s = headline_start, e = #text, hl = agenda_hl.headline }

            local item_lnum = emit(text)
            line_map[item_lnum] = item
            for _, span in ipairs(spans) do
              hls[#hls + 1] = { item_lnum - 1, span.s, span.e, span.hl, field = span.field, state = item.todo_state }
            end
            if marked and marked[item_key(item)] then
              hls[#hls + 1] = { item_lnum - 1, 0, 2, 'OrgSA_Marked', field = 'mark', state = item.todo_state }
            end
          end
        end
      end
    end

    return rows, hls, line_map
  end

  layout.kickstart_doom_compact_layout = true
end

local function setup_classic_layout_highlights()
  local layout = require 'org-super-agenda.core.layout.classic'
  if layout.kickstart_classic_field_highlights then return end

  local original_build = layout.build
  layout.build = function(groups, win_width, cfg, marked)
    local rows, hls, line_map = original_build(groups, win_width, cfg, marked)

    for _, hl in ipairs(hls) do
      if not hl[4] then
        if hl.field == 'filename' then
          hl[4] = agenda_hl.filename
        elseif hl.field == 'headline' then
          hl[4] = agenda_hl.headline
        elseif hl.field == 'date' then
          hl[4] = agenda_hl.date
        elseif hl.field == 'tags' then
          hl[4] = agenda_hl.tags
        elseif hl.field == 'priority' then
          local text = rows[hl[1] + 1] and rows[hl[1] + 1]:sub(hl[2] + 1, hl[3]) or ''
          hl[4] = priority_hl(text:match '%[#([ABC])%]')
        end
      end
    end

    return rows, hls, line_map
  end

  layout.kickstart_classic_field_highlights = true
end

local function priority_rank(priority) return ({ A = 3, B = 2, C = 1 })[priority or ''] or 0 end

local function todo_ranker(order)
  local ranks = {}
  for index, state in ipairs(order or {}) do
    ranks[state] = index
  end

  return function(state) return ranks[state or ''] or 999 end
end

local function days_until_item(item)
  local deadline_days = item.deadline and item.deadline:days_from_today()
  local scheduled_days = item.scheduled and item.scheduled:days_from_today()

  if deadline_days and scheduled_days then return math.min(deadline_days, scheduled_days) end
  return deadline_days or scheduled_days
end

local ok_sort, sort_core = pcall(require, 'org-super-agenda.core.sort')
if ok_sort and not sort_core.kickstart_date_priority_sort then
  local original_sort_items = sort_core.sort_items

  sort_core.sort_items = function(items, spec, cfg)
    if not (spec and spec.by == 'todo' and spec.secondary == 'date_priority') then return original_sort_items(items, spec, cfg) end

    local rank_todo = todo_ranker(spec.todo_order)
    table.sort(items, function(left, right)
      local left_state = rank_todo(left.todo_state)
      local right_state = rank_todo(right.todo_state)
      if left_state ~= right_state then return left_state < right_state end

      local left_date = days_until_item(left) or math.huge
      local right_date = days_until_item(right) or math.huge
      if left_date ~= right_date then return left_date < right_date end

      local left_priority = priority_rank(left.priority)
      local right_priority = priority_rank(right.priority)
      if left_priority ~= right_priority then return left_priority > right_priority end

      local left_file = (left.file or ''):match '[^/]+$' or ''
      local right_file = (right.file or ''):match '[^/]+$' or ''
      if left_file ~= right_file then return left_file < right_file end

      return (left.headline or ''):lower() < (right.headline or ''):lower()
    end)

    return items
  end

  sort_core.kickstart_date_priority_sort = true
end

setup_doom_compact_layout()
setup_classic_layout_highlights()
setup_calendar_event_row_highlights()

local function days_until_week_end()
  local weekday = tonumber(os.date '%w')
  local iso_weekday = weekday == 0 and 7 or weekday
  return 7 - iso_weekday
end

local function is_open_item(item) return item.todo_state ~= 'DONE' end

local current_agenda_groups = {
  {
    name = 'overdue',
    matcher = function(item)
      local days = days_until_item(item)
      return item.todo_state ~= 'DONE' and days and days < 0
    end,
    sort = state_sort,
  },
  {
    name = 'today',
    matcher = function(item)
      local days = days_until_item(item)
      return days == 0
    end,
    sort = state_sort,
  },
  {
    name = 'tomorrow',
    matcher = function(item)
      local days = days_until_item(item)
      return days == 1
    end,
    sort = state_sort,
  },
  {
    name = 'this week',
    matcher = function(item)
      local days = days_until_item(item)
      return days and days > 1 and days <= days_until_week_end()
    end,
    sort = state_sort,
  },
  {
    name = 'next week',
    matcher = function(item)
      local days = days_until_item(item)
      local week_end = days_until_week_end()
      return days and days > week_end and days <= week_end + 7
    end,
    sort = state_sort,
  },
  {
    name = 'upcoming',
    matcher = function(item)
      local days = days_until_item(item)
      local week_end = days_until_week_end()
      local upcoming_days = require('org-super-agenda.config').get().upcoming_days or 30
      return days and days > week_end + 7 and days <= upcoming_days
    end,
    sort = state_sort,
  },
  {
    name = 'unscheduled',
    matcher = function(item) return is_open_item(item) and not days_until_item(item) end,
    sort = state_sort,
  },
}

local function agenda_day_label(offset)
  local timestamp = os.time() + (offset * 24 * 60 * 60)
  return os.date('%a %b %d', timestamp)
end

local function days_since_week_start()
  local weekday = tonumber(os.date '%w')
  local iso_weekday = weekday == 0 and 7 or weekday
  return iso_weekday - 1
end

local function classic_agenda_groups(day_count, include_later)
  local groups = {}

  for offset = 0, day_count - 1 do
    groups[#groups + 1] = {
      name = agenda_day_label(offset),
      matcher = function(item)
        local days = days_until_item(item)
        return is_open_item(item) and days == offset
      end,
      sort = state_sort,
    }
  end

  if include_later then
    groups[#groups + 1] = {
      name = 'later',
      matcher = function(item)
        local days = days_until_item(item)
        return is_open_item(item) and days and (days < 0 or days >= day_count)
      end,
      sort = state_sort,
    }
  end

  groups[#groups + 1] = {
    name = 'unscheduled',
    matcher = function(item) return is_open_item(item) and not days_until_item(item) end,
    sort = state_sort,
  }

  return groups
end

local function week_agenda_groups()
  local monday_offset = -days_since_week_start()
  local groups = {}

  for index = 0, 6 do
    local offset = monday_offset + index
    groups[#groups + 1] = {
      name = agenda_day_label(offset),
      matcher = function(item)
        local days = days_until_item(item)
        return is_open_item(item) and days == offset
      end,
      sort = state_sort,
    }
  end

  groups[#groups + 1] = {
    name = 'unscheduled',
    matcher = function(item) return is_open_item(item) and not days_until_item(item) end,
    sort = state_sort,
  }

  return groups
end

local function setup_custom_view_modes()
  local ok_store, store = pcall(require, 'org-super-agenda.app.store')
  if not ok_store or store.kickstart_custom_view_modes then return end

  local original_set_active_view = store.set_active_view
  store.set_active_view = function(resolved, key)
    original_set_active_view(resolved, key)
    if resolved and resolved.view_mode then store.set_view_mode(resolved.view_mode) end
  end

  local original_clear_active_view = store.clear_active_view
  store.clear_active_view = function()
    original_clear_active_view()
    store.set_view_mode(require('org-super-agenda.config').get().view_mode or 'classic')
  end

  store.kickstart_custom_view_modes = true
end

setup_custom_view_modes()

local function setup_custom_view_ordering()
  local ok_views, views = pcall(require, 'org-super-agenda.core.views')
  if not ok_views or views.kickstart_ordered_views then return end

  views.list = function(custom_views)
    if not custom_views or type(custom_views) ~= 'table' then return {} end

    local out = {}
    for key, def in pairs(custom_views) do
      out[#out + 1] = {
        key = key,
        name = def.name or key,
        keymap = def.keymap,
        filter = def.filter or '',
        order = def.order or 999,
      }
    end
    table.sort(out, function(left, right)
      if left.order ~= right.order then return left.order < right.order end
      return left.name < right.name
    end)
    return out
  end

  views.kickstart_ordered_views = true
end

setup_custom_view_ordering()

require('org-super-agenda').setup {
  org_directories = { org_dir },
  popup_mode = {
    enabled = false,
    hide_command = nil,
  },
  persist_hidden = false,
  todo_states = {
    {
      name = 'TODO',
      keymap = 'ot',
      color = state_colors.TODO,
      strike_through = false,
      fields = { 'todo' },
    },
    {
      name = 'PROGRESS',
      keymap = 'op',
      color = state_colors.PROGRESS,
      strike_through = false,
      fields = { 'todo' },
    },
    {
      name = 'WAIT',
      keymap = 'ow',
      color = state_colors.WAIT,
      strike_through = false,
      fields = { 'todo' },
    },
    {
      name = 'DONE',
      keymap = false,
      color = state_colors.DONE,
      strike_through = true,
      fields = { 'todo', 'headline' },
    },
  },
  groups = week_agenda_groups(),
  group_sort = state_sort,
  upcoming_days = 30,
  show_other_group = false,
  other_group_name = 'unscheduled',
  group_format = '%s',
  view_mode = 'compact',
  compact = { filename_min_width = 10, label_min_width = 12 },
  heading_max_length = 90,
  show_filename = true,
  show_tags = true,
  custom_views = {
    current = {
      name = 'All Tasks',
      title = 'All Tasks',
      order = 4,
      groups = current_agenda_groups,
      sort = state_sort,
      view_mode = 'compact',
    },
    week = {
      name = 'Week',
      title = 'Week',
      order = 1,
      filter = '-is:done',
      groups = week_agenda_groups(),
      sort = state_sort,
      view_mode = 'compact',
    },
    tenday = {
      name = '10 Days',
      title = '10 Days',
      order = 2,
      filter = '-is:done',
      groups = classic_agenda_groups(10, true),
      sort = state_sort,
      view_mode = 'compact',
    },
    month = {
      name = 'Month',
      title = 'Month',
      order = 3,
      filter = '-is:done',
      groups = classic_agenda_groups(30, true),
      sort = state_sort,
      view_mode = 'compact',
    },
  },
}

apply_agenda_highlights()

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('kickstart_org_super_agenda_colors', { clear = true }),
  callback = apply_agenda_highlights,
})

vim.keymap.set('n', '<leader>oa', '<cmd>OrgSuperAgenda!<cr>', { desc = 'Org Super Agenda Fullscreen' })

pcall(function()
  require('which-key').add {
    { '<leader>oa', desc = 'Org Super Agenda' },
  }
end)
