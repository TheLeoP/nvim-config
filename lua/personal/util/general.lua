local api = vim.api

local M = {}

local function get_last_terminal()
  local terminal_channels = {}

  for _, channel in pairs(api.nvim_list_chans()) do
    if channel["mode"] == "terminal" and channel["pty"] ~= "" then
      table.insert(terminal_channels, channel)
    end
  end

  table.sort(terminal_channels, function(left, right)
    return left["buffer"] > right["buffer"]
  end)

  return terminal_channels[1]["id"]
end

local line_end = vim.fn.has "win32" == 1 and "\r\n" or "\n"

function M.visual_ejecutar_en_terminal()
  --- @type integer, integer
  local start_col, _start_row = unpack(api.nvim_buf_get_mark(0, "<"))
  --- @type integer, integer
  local end_col, _end_row = unpack(api.nvim_buf_get_mark(0, ">"))

  local lines = api.nvim_buf_get_lines(0, start_col - 1, end_col, true)

  local commands = table.concat(lines, line_end)
  api.nvim_chan_send(get_last_terminal(), commands)
end

---@param str string
---@param i integer start of the substring (base 1)
---@param j integer|nil end of the substring exclusive (base 1)
---@return string the substring
function M.str_multibyte_sub(str, i, j)
  local length = vim.str_utfindex(str) --[[@as integer]]
  if i < 0 then
    --- @type integer
    i = i + length + 1
  end
  if j and j < 0 then
    --- @type integer
    j = j + length + 1
  end
  local u = (i > 0) and i or 1
  local v = (j and j <= length) and j or length
  if u > v then
    return ""
  end
  local s = vim.str_byteindex(str, u - 1)
  local e = vim.str_byteindex(str, v)
  local aux = str:sub(s + 1, e)
  return aux
end

return M
