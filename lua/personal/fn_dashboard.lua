local M = {}

function M.guardar_sesion()
  local nombre_sesion = vim.fn.input('Ingrese el nombre de la sesión: ')
  vim.cmd('SessionSave ' .. nombre_sesion)
end

function M.cargar_sesion()
  local nombre_sesion = vim.fn.input('Ingrese el nombre de la sesión: ')
  vim.cmd('SessionLoad ' .. nombre_sesion)
end

return M
