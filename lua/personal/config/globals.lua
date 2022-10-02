vim.g.home_dir = vim.api.nvim_eval "$HOME"
vim.g.lsp_borders = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" }

vim.g.ciclo_actual = "9no ciclo"

if vim.fn.has "win32" == 1 then
  vim.g.documentos = "D:/Lucho"
  vim.g.make_cmd = "make"
else
  vim.g.documentos = vim.g.home_dir .. "/Documentos"
  vim.g.make_cmd = "make"
end

vim.g.documentos_u = vim.g.documentos .. "/Documentos U/" .. vim.g.ciclo_actual .. "/"

function _G.expand(...)
  local expanded_value = {}

  for i = 1, select("#", ...) do
    local value = select(i, ...)
    table.insert(expanded_value, vim.inspect(value))
  end
  return expanded_value
end

function _G.put(...)
  local expanded_value = expand(...)
  print(table.concat(expanded_value, "\n"))
end

function _G.put_text(...)
  local expanded_value = expand(...)

  local lines = vim.split(table.concat(expanded_value, "\n"), "\n")
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end
