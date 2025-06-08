local uv = vim.uv

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
    },
  })
end

---@param opts table
---@param cfg string
---@param items vim.lsp.util.locations_to_items.ret[]
local quickfix_run = function(opts, cfg, items)
  if not items then return {} end
  local results = {}

  opts = require("fzf-lua.config").normalize_opts(opts, cfg)
  if not opts then return end

  if not opts.cwd then opts.cwd = uv.cwd() end

  for _, entry in ipairs(items) do
    if entry.valid == 1 or not opts.only_valid then
      entry.text = entry.text:gsub("\r?\n", " ")
      table.insert(results, require("fzf-lua.make_entry").lcol(entry, opts))
    end
  end

  local contents = function(cb)
    for _, x in ipairs(results) do
      x = require("fzf-lua.make_entry").file(x, opts)
      if x then cb(x, function(err)
        if err then return end
        cb(nil)
      end) end
    end
    cb(nil)
  end

  opts = require("fzf-lua.core").set_fzf_field_index(opts)
  return require("fzf-lua").fzf_exec(contents, opts)
end

---@class omnisharp_point
---@field Line integer
---@field Column integer

---@class omnisharp_range
---@field Start omnisharp_point
---@field End omnisharp_point

---@class omnisharp_definition
---@field Location {FileName: string, Range: omnisharp_range}
---@field MetadataSource table<string, unknown>
---@field SourceGeneratedFileInfo table<string, unknown>

---@class omnisharp_quickfix: omnisharp_point
---@field FileName string
---@field GeneratedFileInfo table<string, unknown>
---@field EndLine integer
---@field EndColumn integer

---@alias omnisharp_location {uri: string, range: omnisharp_range}[]

---@param definitions omnisharp_definition[]
---@param client vim.lsp.Client
---@return omnisharp_location []
local function definitions_to_locations(definitions, client)
  local locations = {} ---@type omnisharp_location[]
  local utils = require "omnisharp_utils"
  for _, definition in ipairs(definitions) do
    local file_name = definition.Location.FileName ---@type string|nil

    if definition.MetadataSource then
      local params = {
        timeout = 5000,
      }
      params = vim.tbl_extend("force", params, definition.MetadataSource)
      _, file_name = utils.load_metadata_doc(params, client)
    elseif definition.SourceGeneratedFileInfo then
      local params = {
        timeout = 5000,
      }
      params = vim.tbl_extend("force", params, definition.SourceGeneratedFileInfo)
      _, file_name = utils.load_sourcegen_doc(params, client)
    end

    if file_name then
      table.insert(locations, {
        uri = "file://" .. file_name,
        range = {
          start = {
            line = definition.Location.Range.Start.Line,
            character = definition.Location.Range.Start.Column,
          },
          ["end"] = {
            line = definition.Location.Range.End.Line,
            character = definition.Location.Range.End.Column,
          },
        },
      })
    end
  end
  return locations
end

function M.omnisharp_lsp_definitions()
  local utils = require "omnisharp_utils"

  local client = vim.lsp.get_clients({ bufnr = 0, name = "omnisharp" })[1]
  if not client then return end

  client.request("o#/v2/gotodefinition", utils.cmd_params(client), function(err, result, ctx, config)
    if err then
      return vim.notify(("Omnisharp error: %s"):format(err), vim.log.levels.ERROR, { title = "Omnisharp" })
    end
    if not result or not result.Definitions then
      return vim.notify("No results", vim.log.levels.INFO, { title = "Omnisharp" })
    end
    ---@cast result {Definitions: omnisharp_definition[]}

    local definitions = definitions_to_locations(result.Definitions, client)
    if #definitions == 1 then
      vim.lsp.util.show_document(definitions[1], client.offset_encoding, { focus = true })
    elseif #definitions > 1 then
      local items = vim.lsp.util.locations_to_items(definitions, client.offset_encoding)
      quickfix_run({ winopts = { title = " LSP definitions " } }, "quickfix", items)
    else
      vim.notify("No locations found", vim.log.levels.INFO, { title = "Omnisharp" })
    end
  end)
end

---@param qf omnisharp_quickfix[]
---@param client vim.lsp.Client
---@return omnisharp_location []
local function qf_to_locations(qf, client)
  local locations = {} ---@type omnisharp_location[]
  for _, qf in ipairs(qf) do
    local file_name = qf.FileName ---@type string|nil

    if qf.GeneratedFileInfo then
      local params = {
        timeout = 5000,
      }
      params = vim.tbl_extend("force", params, qf.GeneratedFileInfo)

      _, file_name = utils.load_sourcegen_doc(params, client)
    end

    if file_name then
      table.insert(locations, {
        uri = "file://" .. file_name,
        range = {
          start = {
            line = qf.Line,
            character = qf.Column,
          },
          ["end"] = {
            line = qf.EndLine,
            character = qf.EndColumn,
          },
        },
      })
    end
  end
  return locations
end

function M.omnisharp_lsp_references()
  local utils = require "omnisharp_utils"

  local client = vim.lsp.get_clients({ bufnr = 0, name = "omnisharp" })[1]
  if not client then return end

  client.request("o#/findusages", utils.cmd_params(client), function(err, result, ctx, config)
    if err then
      return vim.notify(("Omnisharp error: %s"):format(err), vim.log.levels.ERROR, { title = "Omnisharp" })
    end
    if not result or not result.QuickFixes then
      return vim.notify("No results", vim.log.levels.INFO, { title = "Omnisharp" })
    end
    ---@cast result {QuickFixes: omnisharp_quickfix[]}

    local references = qf_to_locations(result.QuickFixes, client)
    if #references == 1 then
      vim.lsp.util.show_document(references[1], client.offset_encoding, { focus = true })
    elseif #references > 1 then
      local items = vim.lsp.util.locations_to_items(references, client.offset_encoding)
      quickfix_run({ winopts = { title = " LSP references " } }, "quickfix", items)
    else
      vim.notify("No locations found", vim.log.levels.INFO, { title = "Omnisharp" })
    end
  end)
end

function M.omnisharp_lsp_implementations()
  local utils = require "omnisharp_utils"

  local client = vim.lsp.get_clients({ bufnr = 0, name = "omnisharp" })[1]
  if not client then return end

  client.request("o#/findusages", utils.cmd_params(client), function(err, result, ctx, config)
    if err then
      return vim.notify(("Omnisharp error: %s"):format(err), vim.log.levels.ERROR, { title = "Omnisharp" })
    end
    if not result or not result.QuickFixes then
      return vim.notify("No results", vim.log.levels.INFO, { title = "Omnisharp" })
    end
    ---@cast result {QuickFixes: omnisharp_quickfix[]}

    local implementations = qf_to_locations(result.QuickFixes, client)
    if #implementations == 1 then
      vim.lsp.util.show_document(implementations[1], client.offset_encoding, { focus = true })
    elseif #implementations > 1 then
      local items = vim.lsp.util.locations_to_items(implementations, client.offset_encoding)
      quickfix_run({ winopts = { title = " LSP implementations " } }, "quickfix", items)
    else
      vim.notify("No locations found", vim.log.levels.INFO, { title = "Omnisharp" })
    end
  end)
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
