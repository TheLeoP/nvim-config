vim.g.home_dir = vim.api.nvim_eval "$HOME"
vim.g.lsp_borders = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" }

vim.g.ciclo_actual = "8vo ciclo"

if vim.fn.has "win32" == 1 then
  vim.g.documentos = "D:/Lucho"
  vim.g.os = "Windows"
  vim.g.java_lsp_cmd = "prueba.bat"
  vim.g.make_cmd = "make"
  vim.g.desarrollo_plugins = true
  vim.g.tsserver_library_location = "C:/Users/pcx/AppData/Roaming/npm/node_modules/typescript/lib/tsserverlibrary.js"
else
  vim.g.documentos = vim.g.home_dir .. "/Documentos"
  vim.g.os = "Linux"
  vim.g.java_lsp_cmd = "prueba.sh"
  vim.g.make_cmd = "make"
  vim.g.desarrollo_plugins = false
  vim.g.tsserver_library_location = "/usr/local/lib/node_modules/typescript/lib/tsserverlibrary.js"
end

vim.g.autoregistro = vim.g.documentos .. "/Personal/notas/autoregistro"
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
