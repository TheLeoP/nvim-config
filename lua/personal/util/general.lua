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
---@param i integer
---@param j? integer
---@return string
function M.str_multibyte_sub(str, i, j)
  j = j or vim.str_utfindex(str, "utf-32", #str)
  i = math.min(i - 1, j)
  local first_byte_index = vim.str_byteindex(str, "utf-32", i) + 1
  local last_byte_index = vim.str_byteindex(str, "utf-32", j)
  return str:sub(first_byte_index, last_byte_index)
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
