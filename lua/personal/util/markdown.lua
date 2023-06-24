local M = {}

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
---@param text string[]
local set_text = function(row, start_col, end_col, text)
  vim.api.nvim_buf_set_text(0, row - 1, start_col, row - 1, end_col, text)
end

-- Añade texto en el buffer actual en una posición determinada.
-- La posición es {1-index row, 0-index col}
---@param row integer
---@param col integer
---@param text string[] The text to be added.
local insert_text = function(row, col, text)
  set_text(row, col, col, text)
end

---@param start_row integer
---@param start_col integer
---@param end_col integer
---@param end_row integer
---@param text string Texto con el que se rodeará la palabra
local surround = function(start_row, start_col, end_row, end_col, text)
  insert_text(end_row, end_col + 1, { text })
  insert_text(start_row, start_col, { text })
end

---@alias location { col: {left:integer, right: integer}}

---@param row integer
---@param right_surrounding_start_col integer
---@param right_surrounding_end_col   integer
---@param left_surrounding_start_col  integer
---@param left_surrounding_end_col    integer
local unsurround = function(
  row,
  right_surrounding_start_col,
  right_surrounding_end_col,
  left_surrounding_start_col,
  left_surrounding_end_col
)
  set_text(row, right_surrounding_start_col, right_surrounding_end_col, {})
  set_text(row, left_surrounding_start_col, left_surrounding_end_col, {})
end

---@param surrounding string
local toggle_surround = function(surrounding)
  ---@type integer, integer
  local left_row, left_col = unpack(vim.api.nvim_buf_get_mark(0, "["))
  ---@type integer, integer
  local right_row, right_col = unpack(vim.api.nvim_buf_get_mark(0, "]"))

  local line = vim.api.nvim_buf_get_lines(0, left_row - 1, left_row, true)[1]

  local left_surrounding_start_col = left_col - #surrounding >= 0 and left_col - #surrounding or 0
  local left_surrounding_end_col = left_col - #surrounding >= 0 and left_col or #surrounding

  local right_surrounding_start_col = right_col + 1 < #line and right_col + 1 or #line - #surrounding
  local right_surrounding_end_col = right_col + 1 < #line and right_col + 1 + #surrounding or #line

  local right_text = get_text(right_row, right_surrounding_start_col, right_surrounding_end_col)
  local left_text = get_text(left_row, left_surrounding_start_col, left_surrounding_end_col)

  if left_text == right_text and right_text == surrounding then
    unsurround(
      left_row,
      right_surrounding_start_col,
      right_surrounding_end_col,
      left_surrounding_start_col,
      left_surrounding_end_col
    )
  else
    surround(left_row, left_col, right_row, right_col, surrounding)
  end
end

M.bold = function()
  toggle_surround "**"
end

M.italic = function()
  toggle_surround "*"
end

return M
