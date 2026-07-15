local function hl_color(group, attr)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if ok and hl and hl[attr] then return string.format('#%06x', hl[attr]) end
end

return {
  {
    'akinsho/bufferline.nvim',
    config = function()
      vim.opt.showtabline = 2

      local bg = hl_color('Normal', 'bg') or '#282c34'
      local fg = hl_color('Normal', 'fg') or '#abb2bf'
      local muted = hl_color('Comment', 'fg') or '#5c6370'
      local accent = hl_color('DiagnosticInfo', 'fg') or fg
      local selected_bg = hl_color('Function', 'fg') or '#61afef'

      require('bufferline').setup {
        options = {
          max_name_length = 999,
          always_show_bufferline = true,
          separator_style = { '', '' },
          show_buffer_close_icons = false,
          show_close_icon = false,
          tab_size = 0,
          truncate_names = false,
        },
        highlights = {
          fill = { bg = bg },
          background = { bg = bg, fg = muted },
          buffer_visible = { bg = bg, fg = fg },
          buffer_selected = { bg = selected_bg, fg = bg, bold = false, italic = false },
          close_button = { bg = bg, fg = muted },
          close_button_visible = { bg = bg, fg = muted },
          close_button_selected = { bg = selected_bg, fg = bg },
          duplicate = { bg = bg, fg = muted },
          duplicate_visible = { bg = bg, fg = muted },
          duplicate_selected = { bg = selected_bg, fg = bg, italic = false },
          diagnostic = { bg = bg, fg = muted },
          diagnostic_visible = { bg = bg, fg = muted },
          diagnostic_selected = { bg = selected_bg, fg = bg },
          hint = { bg = bg },
          hint_visible = { bg = bg },
          hint_selected = { bg = selected_bg, fg = bg },
          hint_diagnostic = { bg = bg, fg = muted },
          hint_diagnostic_visible = { bg = bg, fg = muted },
          hint_diagnostic_selected = { bg = selected_bg, fg = bg },
          info = { bg = bg },
          info_visible = { bg = bg },
          info_selected = { bg = selected_bg, fg = bg },
          info_diagnostic = { bg = bg, fg = muted },
          info_diagnostic_visible = { bg = bg, fg = muted },
          info_diagnostic_selected = { bg = selected_bg, fg = bg },
          warning = { bg = bg },
          warning_visible = { bg = bg },
          warning_selected = { bg = selected_bg, fg = bg },
          warning_diagnostic = { bg = bg, fg = muted },
          warning_diagnostic_visible = { bg = bg, fg = muted },
          warning_diagnostic_selected = { bg = selected_bg, fg = bg },
          error = { bg = bg },
          error_visible = { bg = bg },
          error_selected = { bg = selected_bg, fg = bg },
          error_diagnostic = { bg = bg, fg = muted },
          error_diagnostic_visible = { bg = bg, fg = muted },
          error_diagnostic_selected = { bg = selected_bg, fg = bg },
          indicator_selected = { bg = selected_bg, fg = bg },
          modified = { bg = bg, fg = accent },
          modified_visible = { bg = bg, fg = accent },
          modified_selected = { bg = selected_bg, fg = bg },
          separator = { bg = bg, fg = bg },
          separator_visible = { bg = bg, fg = bg },
          separator_selected = { bg = bg, fg = selected_bg },
          tab = { bg = bg, fg = muted },
          tab_selected = { bg = selected_bg, fg = bg },
          tab_separator = { bg = bg, fg = bg },
          tab_separator_selected = { bg = bg, fg = selected_bg },
          trunc_marker = { bg = bg, fg = muted },
        },
      }
    end,
  },
}
