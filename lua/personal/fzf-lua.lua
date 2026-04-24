local M = {}

function M.projects()
  local recent_task = require("project_nvim").get_recent()
  recent_task:wait(function(err, recent)
    if err then return vim.notify(err, vim.log.levels.ERROR) end
    local preview = vim.fn.executable "eza" == 1 and "eza -la --color=always --icons -g --group-directories-first {1}"
      or "ls -la {1}"
    if vim.fn.has "win32" == 1 then preview = "dir {1}" end
    require("fzf-lua").fzf_exec(recent, {
      actions = {
        ["default"] = function(selected)
          local config = require "session_manager.config"
          local project_path = selected[1] ---@type string

          vim.cmd.tcd { args = { project_path }, mods = { silent = true } }

          local session_name = config.dir_to_session_filename(vim.loop.cwd()) --- @type {exists: fun():boolean}
          if session_name:exists() then
            require("session_manager").load_current_dir_session(true)
          else
            require("fzf-lua").files { cwd = project_path }
          end
        end,
        ["ctrl-f"] = function(selected)
          local project_path = selected[1] ---@type string
          require("fzf-lua").files { cwd = project_path }
        end,
        ["alt-F"] = function(selected)
          local project_path = selected[1] ---@type string
          require("fzf-lua").live_grep { cwd = project_path }
        end,
        ["ctrl-d"] = {
          fn = function(selected)
            require("project_nvim.utils.history").delete(selected[1])
          end,
          reload = true,
        },
      },
      preview = preview,
      fzf_opts = {
        ["--tiebreak"] = "index",
      },
    })
  end)
end

return M
