local function open_and_close()
  require("overseer").open { enter = false }

  vim.defer_fn(function()
    if vim.bo.filetype ~= "OverseerList" and vim.bo.buftype ~= "terminal" then require("overseer").close() end
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

    local task = overseer.new_task {
      cmd = input,
      components = {
        { "on_exit_set_status" },
        "on_complete_notify",
        "on_complete_dispose",
      },
      render = function(task)
        return require("overseer.render").format_compact(task)
      end,
    }
    task:start()
  end)
end

return {
  {
    "stevearc/overseer.nvim",
    ---@type overseer.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      output = {
        use_terminal = true,
      },
      dap = true,
      ---@diagnostic disable-next-line: missing-fields
      task_list = {
        direction = "bottom",
        max_width = { 600, 0.7 },
        keymaps = {
          ["<C-t>"] = {
            "keymap.run_action",
            opts = { action = "zoom" },
            desc = "Open task output in new tab and close task list",
          },
          ["<up>"] = "keymap.prev_task",
          ["<down>"] = "keymap.next_task",
          ["?"] = false,
          ["q"] = false,
          ["{"] = false,
          ["}"] = false,
        },
      },
      templates = {
        "builtin",
        "personal.cs.clean",
        "personal.cs.build",
        "personal.cs.test",
        "personal.cs.run",
      },
      ---@diagnostic disable-next-line: missing-fields
      form = {
        win_opts = { winblend = 0 },
      },
      confirm = {
        win_opts = { winblend = 5 },
      },
      ---@diagnostic disable-next-line: missing-fields
      task_win = {
        win_opts = { winblend = 5 },
      },
      actions = {
        zoom = {
          desc = "Open task output in new tab and close task list",
          condition = function(task)
            return task:get_bufnr() ~= nil
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
        overseer.run_task({}, function(task)
          if not task then return end
          open_and_close()
        end)
      end, { desc = "Run task" })

      -- vim-dispatch style keymaps
      vim.keymap.set("n", "' ", start_prompt)
    end,
  },
}
