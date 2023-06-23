vim.g.lsp_borders = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" }

vim.g.ciclo_actual = "10mo ciclo"

if vim.fn.has "win32" == 1 then
  vim.g.documentos = "D:/Lucho"
else
  vim.g.documentos = vim.api.nvim_eval "$HOME" .. "/Documentos"
end

vim.g.documentos_u = vim.g.documentos .. "/Documentos U/" .. vim.g.ciclo_actual .. "/"

local function expand(...)
  local expanded_value = {}

  for i = 1, select("#", ...) do
    local value = select(i, ...)
    table.insert(expanded_value, vim.inspect(value))
  end
  return expanded_value
end

function _G.put_text(...)
  local expanded_value = expand(...)

  local lines = vim.split(table.concat(expanded_value, "\n"), "\n")
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, lnum, lnum, true, lines)
end
