local uv = vim.uv

local M = {}

---@param cb function
---@param ms integer
function M.throttle(cb, ms)
  local timer ---@type uv.uv_timer_t|nil

  return function()
    -- if the function is alreaydy waiting to be executed, don't execute it
    -- until the previous one has finished
    if timer then return end
    timer = assert(uv.new_timer())
    timer:start(ms, 0, function()
      timer:stop()
      timer:close()
      timer = nil

      cb()
    end)
  end
end

--NOTE: for small values of `ms`, if called multiple times, the function may be
--executed once on the first call and once after the last one
---@param cb function
---@param ms integer
function M.debounce(cb, ms)
  local timer ---@type uv.uv_timer_t|nil

  return function()
    -- always start the timer, even if it's running. This will delay it's
    -- execution until the last call
    if not timer then timer = assert(uv.new_timer()) end
    timer:start(ms, 0, function()
      timer:stop()
      timer:close()
      timer = nil

      cb()
    end)
  end
end

return M
