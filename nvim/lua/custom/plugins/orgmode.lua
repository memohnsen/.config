return {
  {
    'memohnsen/orgmode',
    build = function(plugin)
      local result = vim.system({
        vim.v.progpath,
        '--clean',
        '--headless',
        '--cmd',
        'set rtp+=' .. plugin.dir,
        '+lua require("orgmode.utils.treesitter.install").run("install")',
        '+qa',
      }):wait()
      if result.code ~= 0 then error('Failed to build Orgmode tree-sitter parser:\n' .. (result.stderr or result.stdout or '')) end
    end,
    config = function()
      local function setup() require('orgmode').setup { pack = { org_dir = '~/dev/org' } } end
      setup()
    end,
  },
}
