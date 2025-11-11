local M = {}

function M.projects()
  local results = require("project_nvim.utils.history").get_recent_projects()
  require("fzf-lua").fzf_exec(results, {
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
          require("project_nvim.utils.history").delete_project(selected[1])
        end,
        reload = true,
      },
    },
    preview = vim.fn.executable "eza" and "eza -la --color=always --icons -g --group-directories-first {1}"
      or "ls -la {1}",
  })
end

---@param list_global boolean
---@param recency_weight number
---@param opts {fzf:table|nil, mini:table|nil}
local select_path = function(list_global, recency_weight, opts)
  local visits = require "mini.visits"
  local fzf_opts = opts.fzf or {}
  local mini_opts = opts.mini or {}

  local sort = visits.gen_sort.default { recency_weight = recency_weight }
  mini_opts.sort = sort
  local cwd = list_global and "" or vim.fn.getcwd()
  local paths = visits.list_paths(cwd, mini_opts) ---@type string[]

  fzf_opts = require("fzf-lua.config").normalize_opts(fzf_opts, "files")
  require("fzf-lua").fzf_exec(function(cb)
    for _, x in ipairs(paths) do
      local make_entry = require "fzf-lua.make_entry"
      x = make_entry.file(x, { cwd = cwd, file_icons = true, color_icons = true })
      if x then cb(x, function(err)
        if err then return end
        cb(nil)
      end) end
    end
    cb(nil)
  end, fzf_opts)
end

---@param path string|nil
---@param cwd string|nil
---@param opts table|nil
local select_label = function(path, cwd, opts)
  local visits = require "mini.visits"
  local items = visits.list_labels(path, cwd, opts)
  opts = opts or {}
  local on_choice = function(label)
    if label == nil then return end

    -- Select among subset of paths with chosen label
    local filter_cur = opts.filter or visits.gen_filter.default()
    local new_opts = vim.deepcopy(opts)
    new_opts.filter = function(path_data)
      return filter_cur(path_data) and type(path_data.labels) == "table" and path_data.labels[label]
    end
    select_path(path == "", 1, { mini = new_opts })
  end

  vim.ui.select(items, { prompt = "Visited labels" }, on_choice)
end

M.mini_visit = {
  recent_cwd = function()
    select_path(false, 1, { winopts = { title = "Select recent (cwd)" } })
  end,
  recent_all = function()
    select_path(true, 1, { winopts = { title = "Select recent (all)" } })
  end,
  frecent_cwd = function()
    select_path(false, 0.5, { winopts = { title = "Select frecent (cwd)" } })
  end,
  frecent_all = function()
    select_path(true, 0.5, { winopts = { title = "Select frecent (all)" } })
  end,
  frequent_cwd = function()
    select_path(false, 0, { winopts = { title = "Select frequent (cwd)" } })
  end,
  frequent_all = function()
    select_path(true, 0, { winopts = { title = "Select frequent (all)" } })
  end,
  select_label_cwd = select_label,
  select_label_all = function()
    select_label("", "")
  end,
}

return M
