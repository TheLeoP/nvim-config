local uv = vim.uv

local M = {}

---@param path string
---@param flags string|integer
---@param mode integer
---@return nil|string err, integer|nil fd
function M.fs_open(path, flags, mode)
  local co = coroutine.running()
  uv.fs_open(path, flags, mode, function(err, fd) coroutine.resume(co, err, fd) end)
  return coroutine.yield()
end

---@param fd integer
---@param size integer
---@param offset integer|nil
---@return nil|string err, string|nil data
function M.fs_read(fd, size, offset)
  local co = coroutine.running()
  uv.fs_read(fd, size, offset, function(err, data) coroutine.resume(co, err, data) end)
  return coroutine.yield()
end

---@param path string
---@return nil|string err, table|nil stat
function M.fs_stat(path)
  local co = coroutine.running()
  uv.fs_stat(path, function(err, stat) coroutine.resume(co, err, stat) end)
  return coroutine.yield()
end

---@param fd integer
---@return nil|string err, table|nil stat
function M.fs_fstat(fd)
  local co = coroutine.running()
  uv.fs_fstat(fd, function(err, stat) coroutine.resume(co, err, stat) end)
  return coroutine.yield()
end

---@param fd integer
---@return nil|string err, table|nil stat
function M.fs_close(fd)
  local co = coroutine.running()
  uv.fs_close(fd, function(err, success) coroutine.resume(co, err, success) end)
  return coroutine.yield()
end

return M
