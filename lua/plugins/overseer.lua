local function open_and_close()
  local overseer = require "overseer"

  overseer.open { enter = false }

  vim.defer_fn(function()
    if vim.bo.filetype ~= "OverseerList" and vim.bo.buftype ~= "terminal" then overseer.close() end
  end, 10 * 1000)
end

local function restart_last_task()
  local overseer = require "overseer"
  local tasks = overseer.list_tasks { recent_first = true }
  if vim.tbl_isempty(tasks) then
    vim.notify("No tasks found", vim.log.levels.WARN)
  else
    overseer.run_action(tasks[1], "restart")
    open_and_close()
  end
end

local function run_task()
  local overseer = require "overseer"
  overseer.run_template({}, function(task)
    if not task then return end
    open_and_close()
  end)
end

local function start_prompt()
  local overseer = require "overseer"
  vim.ui.input({ prompt = "cmd: ", completion = "file" }, function(input)
    if not input or input == "" then return end
    overseer.run_template({
      name = "shell",
      prompt = "never",
      params = {
        cmd = input,
        components = {
          { "display_duration", detail_level = 2 },
          { "on_exit_set_status", success_codes = { 0, 1 } },
          "on_complete_notify",
          "on_complete_dispose",
        },
      },
    }, function(task)
      if not task then return end
      open_and_close()
    end)
  end)
end

return {
  {
    "stevearc/overseer.nvim",
    opts = {
      strategy = "jobstart",
      dap = true,
      task_list = {
        default_detail = 2,
        direction = "bottom",
        max_width = { 600, 0.7 },
        bindings = {
          ["<C-b>"] = "ScrollOutputUp",
          ["<C-f>"] = "ScrollOutputDown",
          ["H"] = "IncreaseAllDetail",
          ["L"] = "DecreaseAllDetail",
          ["g?"] = false,
          ["<C-l>"] = false,
          ["<C-h>"] = false,
          ["{"] = false,
          ["}"] = false,
        },
      },
      templates = { "builtin", "personal.cs.clean", "personal.cs.build", "personal.cs.test" },
      form = {
        win_opts = { winblend = 0 },
      },
      confirm = {
        win_opts = { winblend = 5 },
      },
      task_win = {
        win_opts = { winblend = 5 },
      },
    },
    config = function(_, opts)
      local overseer = require "overseer"
      overseer.setup(opts)

      vim.keymap.set("n", "<leader>ot", "<cmd>OverseerToggle<cr>", { desc = "Toggle task window" })
      vim.keymap.set("n", "<leader>o<", restart_last_task, { desc = "Restart last task" })
      vim.keymap.set("n", "<leader>or", run_task, { desc = "Run task" })

      -- vim-dispatch style keymaps
      vim.keymap.set("n", "' ", start_prompt)
    end,
  },
}
