-- ported from https://github.com/vuciv/vim-bujo

local fs_exists = require("personal.util.general").fs_exists

local M = {}

local data_path = ("%s/%s"):format(vim.fn.stdpath "data", "/bujo")
data_path = vim.fs.normalize(data_path)
local default_width = 30

fs_exists(
  data_path,
  vim.schedule_wrap(function(exists, err)
    if exists == nil and err then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    if not exists then vim.fn.mkdir(data_path) end
  end)
)

---@param cb fun(is: boolean)
local function is_git_repo(cb)
  vim.system({ "git", "rev-parse", "--is-inside-work-tree" }, { text = true }, function(result)
    if result.stderr ~= "" then
      cb(false)
      return
    end

    local out = vim.split(result.stdout, "\n")[1]
    if out ~= "true" then
      cb(false)
      return
    end

    cb(true)
  end)
end

---@param cb fun(name: string|nil)
local function repo_name(cb)
  vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }, function(result)
    if result.stderr ~= "" then
      vim.notify(result.stderr, vim.log.levels.ERROR)
      cb()
      return
    end

    if result.stderr ~= "" then
      vim.notify(result.stderr, vim.log.levels.ERROR)
      cb()
      return
    end
    local out = vim.split(result.stdout, "\n")[1]
    local segments = vim.split(out, "/")
    local name = segments[#segments]
    cb(name)
  end)
end

---@param cb fun(path: string)
local function get_path(cb)
  is_git_repo(function(is)
    if not is then
      cb(("%s/todo.md"):format(data_path))
      return
    end
    repo_name(function(name)
      if name == nil then return end
      local todo_path = ("%s/%s"):format(data_path, name)
      fs_exists(
        todo_path,
        vim.schedule_wrap(function(exists, err)
          if exists == nil and err then
            vim.notify(err, vim.log.levels.ERROR)
            return
          end
          if not exists then vim.fn.mkdir(todo_path) end
          cb(("%s/todo.md"):format(todo_path))
        end)
      )
    end)
  end)
end

---@param width? integer
function M.open(width)
  get_path(vim.schedule_wrap(
    function(path)
      vim.cmd.vsplit {
        range = { width or default_width },
        args = { path },
        mods = { split = "aboveleft" },
      }
    end
  ))
end
return M
