vim.pack.add {
  { src = 'https://github.com/memohnsen/orgmode' },
}

require('orgmode').setup {
  pack = {
    org_dir = '~/dev/org',
  },
}
