local uv = vim.uv

--- Coroutine friendly libuv wrappers, coroutines utils and vim.schedule util
local M = {}

---@param co thread
---@param ... any
function M.co_resume(co, ...)
  local ok, err = coroutine.resume(co, ...)
  if not ok then vim.notify(debug.traceback(co, err), vim.log.levels.ERROR) end
end

---@async
function M.schedule()
  local co = coroutine.running()
  vim.schedule(function()
    M.co_resume(co)
  end)
  coroutine.yield()
end

---@async
---@param path string
---@param flags string|integer
---@param mode integer
---@return nil|string err, integer|nil fd
function M.fs_open(path, flags, mode)
  local co = coroutine.running()
  uv.fs_open(path, flags, mode, function(err, fd)
    M.co_resume(co, err, fd)
  end)
  return coroutine.yield()
end

---@async
---@param fd integer
---@param size integer
---@param offset integer|nil
---@return nil|string err, string|nil data
function M.fs_read(fd, size, offset)
  local co = coroutine.running()
  uv.fs_read(fd, size, offset, function(err, data)
    M.co_resume(co, err, data)
  end)
  return coroutine.yield()
end

---@async
---@param path string
---@return nil|string err, table|nil stat
function M.fs_stat(path)
  local co = coroutine.running()
  uv.fs_stat(path, function(err, stat)
    M.co_resume(co, err, stat)
  end)
  return coroutine.yield()
end

---@async
---@param fd integer
---@return nil|string err, table|nil stat
function M.fs_fstat(fd)
  local co = coroutine.running()
  uv.fs_fstat(fd, function(err, stat)
    M.co_resume(co, err, stat)
  end)
  return coroutine.yield()
end

---@async
---@param fd integer
---@return nil|string err, boolean|nil success
function M.fs_close(fd)
  local co = coroutine.running()
  uv.fs_close(fd, function(err, success)
    M.co_resume(co, err, success)
  end)
  return coroutine.yield()
end

---@async
---@param fd integer
---@param data string
---@param offset integer|nil
---@return nil|string err, integer|nil bytes
function M.fs_write(fd, data, offset)
  local co = coroutine.running()
  uv.fs_write(fd, data, offset, function(err, bytes)
    M.co_resume(co, err, bytes)
  end)
  return coroutine.yield()
end

return M
