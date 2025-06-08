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
    return
  end
  overseer.run_action(tasks[1], "restart")
  vim.notify "Running last task"
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
    ---@type overseer.Config
    opts = {
      strategy = "terminal",
      dap = true,
      task_list = {
        default_detail = 2,
        direction = "bottom",
        max_width = { 600, 0.7 },
        bindings = {
          ["<C-t>"] = "<CMD>OverseerQuickAction zoom<CR>",
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
      actions = {
        zoom = {
          desc = "Open terminal in new tab and close task list",
          condition = function(task)
            return task:get_bufnr()
          end,
          run = function(task)
            require("overseer").close()
            task:open_output "tab"
          end,
        },
      },
    },
    config = function(_, opts)
      local overseer = require "overseer"
      overseer.setup(opts)

      -- follows my general `toggle` convention for keymaps
      vim.keymap.set("n", "<leader>to", "<cmd>OverseerToggle<cr>", { desc = "Toggle task window" })

      vim.keymap.set("n", "<leader>o<", restart_last_task, { desc = "Restart last task" })
      vim.keymap.set("n", "<leader>or", function()
        overseer.run_template({}, function(task)
          if not task then return end
          open_and_close()
        end)
      end, { desc = "Run task" })

      -- vim-dispatch style keymaps
      vim.keymap.set("n", "' ", start_prompt)
    end,
  },
}
