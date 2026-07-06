-- Personal orgmode fork (~/dev/orgmode, github.com/memohnsen/orgmode).
-- All workflow customizations (ux, notes, theme, bullets, snippets,
-- super-agenda) live in the fork's lua/orgmode/pack/ modules and activate
-- from setup(). Loaded from the local checkout so edits are live.
vim.opt.runtimepath:prepend(vim.fn.expand '~/dev/orgmode')

require('orgmode').setup {
  pack = {
    org_dir = '~/dev/org',
  },
}
