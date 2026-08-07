return {
  {
    'swaits/zellij-nav.nvim',
    event = 'VeryLazy',
    keys = {
      { '<A-h>', '<cmd>ZellijNavigateLeftTab<CR>', desc = 'Navigate left or tab', silent = true },
      { '<A-j>', '<cmd>ZellijNavigateDown<CR>', desc = 'Navigate down', silent = true },
      { '<A-k>', '<cmd>ZellijNavigateUp<CR>', desc = 'Navigate up', silent = true },
      { '<A-l>', '<cmd>ZellijNavigateRightTab<CR>', desc = 'Navigate right or tab', silent = true },
    },
    opts = {},
  },
}
