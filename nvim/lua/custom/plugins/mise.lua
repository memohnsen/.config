return {
  {
    name = 'mise-tasks',
    dir = vim.fn.stdpath 'config',
    config = function()
      local function open_terminal(task, interactive)
        vim.cmd 'tabnew'
        local buffer = vim.api.nvim_get_current_buf()

        vim.keymap.set('n', 'q', function()
          if #vim.api.nvim_list_tabpages() > 1 then vim.cmd 'tabclose' end
          if vim.api.nvim_buf_is_valid(buffer) then vim.api.nvim_buf_delete(buffer, { force = true }) end
        end, { buffer = buffer, desc = 'Close Mise output', silent = true })

        vim.fn.jobstart({ 'mise', 'run', task }, { cwd = vim.fn.getcwd(), term = true })
        if interactive then vim.cmd 'startinsert' end
      end

      local function run_in_zellij_scratch()
        if not vim.env.ZELLIJ or vim.fn.executable 'zellij' ~= 1 then return false end
        local open_scratch = vim.system({ 'zellij', 'action', 'go-to-tab-name', 'scratch', '--create' }):wait()
        if open_scratch.code ~= 0 then return false end
        local command = 'cd ' .. vim.fn.shellescape(vim.fn.getcwd()) .. ' && mise run run'
        local result = vim.system({ 'zellij', 'action', 'write-chars', command }):wait()
        if result.code ~= 0 then return false end
        vim.system({ 'zellij', 'action', 'send-keys', 'Enter' })
        return true
      end

      local function select_task()
        local result = vim.system({ 'mise', 'tasks', 'ls', '--name-only' }, { cwd = vim.fn.getcwd(), text = true }):wait()
        if result.code ~= 0 then
          vim.notify(result.stderr or 'Could not read mise.toml', vim.log.levels.ERROR)
          return
        end
        local tasks = vim.split(vim.trim(result.stdout), '\n', { trimempty = true })
        vim.ui.select(tasks, { prompt = 'Mise task: ' }, function(task)
          if task then
            if task == 'run' and run_in_zellij_scratch() then return end
            open_terminal(task, task == 'run')
          end
        end)
      end

      vim.keymap.set('n', '<leader>j', select_task, { desc = 'Mise Tasks' })
    end,
  },
}
