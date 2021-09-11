vim.g.home_dir = vim.api.nvim_eval('$HOME')
vim.g.lsp_borders = { '┏', '━', '┓', '┃', '┛', '━', '┗', '┃' }
vim.g.ciclo_actual = '7mo ciclo'

if vim.fn.has("win32") == 1 then
  vim.g.documentos = 'D:/Lucho'
  vim.g.os = "Windows"
  vim.g.java_lsp_cmd = "prueba.bat"
  vim.g.make_cmd = 'bash -c make'
else
  vim.g.documentos = vim.g.home_dir .. '/Documentos'
  vim.g.os = "Linux"
  vim.g.java_lsp_cmd = "prueba.sh"
  vim.g.make_cmd = 'make'
end

vim.g.notas_emociones = vim.g.documentos .. '/Personal/psicologa/autoregistro-emociones'
vim.g.documentos_u = vim.g.documentos .. '/Documentos U/' .. vim.g.ciclo_actual .. '/'


function _G.put(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, '\n'))
  return ...
end

function _G.put_text(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, '\n'), '\n')
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end
