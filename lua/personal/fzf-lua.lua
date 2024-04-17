local M = {}

function M.projects()
  local results = require("project_nvim.utils.history").get_recent_projects()
  require("fzf-lua").fzf_exec(results, {
    actions = {
      ["default"] = function(selected)
        local config = require "session_manager.config"
        local project_path = selected[1] ---@type string

        vim.cmd.tcd(project_path)

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
    },
  })
end

return M
