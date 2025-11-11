local api = vim.api
local auv = require "personal.auv"
local iter = vim.iter
local debounce = require("personal.dedup").debounce

local M = {}

---@class personal.channel
---@field id integer
---@field argv? string[]
---@field stream 'stdio'|'stderr'|'socket'|'job'
---@field mode 'bytes'|'terminal'|'rpc'
---@field pty? string
---@field buffer? integer
---@field client? table

local function last_terminal()
  ---@type personal.channel[]
  local terminal_channels = iter(api.nvim_list_chans())
    :filter(
      ---@param channel personal.channel
      function(channel)
        return channel.mode == "terminal" and channel.pty ~= nil
      end
    )
    :totable()
  if vim.tbl_isempty(terminal_channels) then return end

  table.sort(terminal_channels, function(left, right)
    return left.buffer > right.buffer
  end)

  return terminal_channels[1].id
end

---@param type 'line'|'char'|'block'
function M.eval_in_last_term(type)
  local last_term = last_terminal()
  if not last_term then return vim.notify "An opened terminal couldn't be found" end

  local range_type = type == "line" and "V" or type == "char" and "v" or "\22"

  local lines = vim.fn.getregion(vim.fn.getpos "'[", vim.fn.getpos "']", { type = range_type })
  table.insert(lines, "")

  api.nvim_chan_send(last_term, table.concat(lines, "\r\n"))
end

---@param str string
---@param i integer start of the substring (base 1)
---@param j integer|nil end of the substring exclusive (base 1)
---@return string the substring
function M.str_multibyte_sub(str, i, j)
  local length = vim.str_utfindex(str, "utf-8") --[[@as integer]]
  if i < 0 then i = i + length + 1 end
  if j and j < 0 then j = j + length + 1 end
  local u = (i > 0) and i or 1
  local v = (j and j <= length) and j or length
  if u > v then return "" end
  local s = vim.str_byteindex(str, "utf-8", u - 1)
  local e = vim.str_byteindex(str, "utf-8", v)
  return str:sub(s + 1, e)
end

---@async
---@param path string
---@return boolean|nil exists, string|nil err
function M.fs_exists(path)
  local err = auv.fs_stat(path)
  if not err then return true end

  if not err:match "^ENOENT:" then return nil, err end
  return false
end

M.clear_system_notifications = debounce(function()
  -- TODO: windows support
  if vim.fn.has "win32" ~= 1 then
    vim.system({ "dunstctl", "close-all" }, nil, function(out)
      if out.stderr ~= "" then vim.notify(out.stderr, vim.log.levels.ERROR) end
    end)
  end
end, 50)

return M
