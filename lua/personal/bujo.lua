-- ported from https://github.com/vuciv/vim-bujo

local fs_exists = require("personal.util.general").fs_exists
local auv = require "personal.auv"
local co_resume = require("personal.auv").co_resume

local M = {}

local data_path = ("%s/%s"):format(vim.fn.stdpath "data", "/bujo")
data_path = vim.fs.normalize(data_path)
local default_width = 30

coroutine.wrap(function()
  local exists, err = fs_exists(data_path)
  if exists == nil and err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  if not exists then
    auv.schedule()
    vim.fn.mkdir(data_path)
  end
end)()

---@async
---@return boolean is
local function is_git_repo()
  local co = coroutine.running()
  vim.system(
    { "git", "rev-parse", "--is-inside-work-tree" },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.stderr ~= "" then
        co_resume(co, false)
        return
      end

      local out = vim.split(result.stdout, "\n")[1]
      if out ~= "true" then
        co_resume(co, false)
        return
      end
      co_resume(co, true)
    end)
  )
  return coroutine.yield()
end

---@async
---@return string|nil name
local function repo_name()
  local co = coroutine.running()

  vim.system(
    { "git", "rev-parse", "--show-toplevel" },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.stderr ~= "" then
        vim.notify(result.stderr, vim.log.levels.ERROR)
        co_resume(co)
        return
      end

      if result.stderr ~= "" then
        vim.notify(result.stderr, vim.log.levels.ERROR)
        co_resume(co)
        return
      end
      local out = vim.split(result.stdout, "\n")[1]
      local segments = vim.split(out, "/")
      local name = segments[#segments]
      co_resume(co, name)
    end)
  )
  return coroutine.yield()
end

---@async
---@return string|nil path
local function get_path()
  if not is_git_repo() then return ("%s/todo.md"):format(data_path) end
  if repo_name() == nil then return ("%s/todo.md"):format(data_path) end
  local todo_path = ("%s/%s"):format(data_path, repo_name())
  local exists, err = fs_exists(todo_path)
  if err then return vim.notify(err, vim.log.levels.ERROR) end
  if exists == nil then return end
  if not exists then
    auv.schedule()
    vim.fn.mkdir(todo_path)
  end
  return ("%s/todo.md"):format(todo_path)
end

---@param width? integer
function M.open(width)
  coroutine.wrap(function()
    local path = get_path()
    if not path then return end
    auv.schedule()
    vim.cmd.vsplit {
      range = { width or default_width },
      args = { path },
      mods = { split = "aboveleft" },
    }
  end)()
end
return M
