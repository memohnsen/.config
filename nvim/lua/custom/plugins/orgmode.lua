-- Personal orgmode fork (github.com/memohnsen/orgmode).
-- All workflow customizations (ux, notes, theme, bullets, snippets,
-- super-agenda) live in the fork's lua/orgmode/pack/ modules and activate
-- from setup().
vim.pack.add {
  { src = 'https://github.com/memohnsen/orgmode' },
}

-- To develop against the local checkout instead of the GitHub repo, comment out
-- the pack entry above and uncomment these two lines:
-- vim.opt.runtimepath:prepend(vim.fn.expand '~/dev/orgmode')
-- vim.cmd 'runtime plugin/orgmode.lua'

require('orgmode').setup {
  pack = {
    org_dir = '~/dev/org',
  },
}
