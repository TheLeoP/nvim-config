local uv = vim.uv

-- TODO: maybe refactor this and dependencies to not be schedule_wrapped
--- Coroutine friendly and vim.schedule_wrapped libuv wrappers
local M = {}

---@param co thread
---@param ... any
function M.co_resume(co, ...)
  local ok, err = coroutine.resume(co, ...)
  if not ok then vim.notify(debug.traceback(co, err), vim.log.levels.ERROR) end
end

---@async
---@param path string
---@param flags string|integer
---@param mode integer
---@return nil|string err, integer|nil fd
function M.fs_open(path, flags, mode)
  local co = coroutine.running()
  uv.fs_open(path, flags, mode, vim.schedule_wrap(function(err, fd) M.co_resume(co, err, fd) end))
  return coroutine.yield()
end

---@async
---@param fd integer
---@param size integer
---@param offset integer|nil
---@return nil|string err, string|nil data
function M.fs_read(fd, size, offset)
  local co = coroutine.running()
  uv.fs_read(fd, size, offset, vim.schedule_wrap(function(err, data) M.co_resume(co, err, data) end))
  return coroutine.yield()
end

---@async
---@param path string
---@return nil|string err, table|nil stat
function M.fs_stat(path)
  local co = coroutine.running()
  uv.fs_stat(path, vim.schedule_wrap(function(err, stat) M.co_resume(co, err, stat) end))
  return coroutine.yield()
end

---@async
---@param fd integer
---@return nil|string err, table|nil stat
function M.fs_fstat(fd)
  local co = coroutine.running()
  uv.fs_fstat(fd, vim.schedule_wrap(function(err, stat) M.co_resume(co, err, stat) end))
  return coroutine.yield()
end

---@async
---@param fd integer
---@return nil|string err, table|nil stat
function M.fs_close(fd)
  local co = coroutine.running()
  uv.fs_close(fd, vim.schedule_wrap(function(err, success) M.co_resume(co, err, success) end))
  return coroutine.yield()
end

return M
