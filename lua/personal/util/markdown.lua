local M = {}

---@param line_num integer
---@return string
local get_line = function(line_num)
  return vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, true)[1]
end

---@param row integer
---@param start_col integer
---@param end_col integer
---@return string
local get_text = function(row, start_col, end_col)
  return vim.api.nvim_buf_get_text(0, row - 1, start_col, row - 1, end_col, {})[1]
end

---@param row integer
---@param start_col integer
---@param end_col integer
---@param text? string[]
local set_text = function(row, start_col, end_col, text)
  local _text = text or {}
  vim.api.nvim_buf_set_text(0, row - 1, start_col, row - 1, end_col, _text)
end

-- Añade texto en el buffer actual en una posición determinada.
-- La posición es {1-index row, 0-index col}
---@param pos integer[] The position to be inserted at.
---@param text string[] The text to be added.
local insert_text = function(pos, text)
  set_text(pos[1], pos[2], pos[2], text)
end

---@param text string Texto con el que se rodeará la palabra
local surround = function(starting, ending, text)
  local ending_target = { ending[1], ending[2] + 1 }
  local starting_target = { starting[1], starting[2] }

  insert_text(ending_target, { text })
  insert_text(starting_target, { text })
end

---@alias location {row: integer, col: {left:integer, right: integer}}

---@param l location
---@param r location
local unsurround = function(l, r)
  set_text(r.row, r.col.left, r.col.right)
  set_text(l.row, l.col.left, l.col.right)
end

local toggle_surround = function(text)
  ---@type integer[]
  local l = vim.api.nvim_buf_get_mark(0, "[")
  ---@type integer[]
  local r = vim.api.nvim_buf_get_mark(0, "]")

  local line = get_line(r[1])

  ---@type location
  local l_text_location = {
    row = l[1],
    col = (l[2] - #text >= 0) and {
      left = l[2] - #text,
      right = l[2],
    } or {
      left = 0,
      right = #text,
    },
  }
  ---@type location
  local r_text_location = {
    row = r[1],
    col = (r[2] + 1 < #line) and {
      left = r[2] + 1,
      right = r[2] + #text + 1,
    } or {
      left = #line - #text,
      right = #line,
    },
  }

  local right_text = get_text(r_text_location.row, r_text_location.col.left, r_text_location.col.right)
  local left_text = get_text(l_text_location.row, l_text_location.col.left, l_text_location.col.right)

  if left_text == right_text and right_text == text then
    unsurround(l_text_location, r_text_location)
  else
    surround(l, r, text)
  end
end

M.bold = function()
  toggle_surround "**"
end

M.italic = function()
  toggle_surround "*"
end

return M
