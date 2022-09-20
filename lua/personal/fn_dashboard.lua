local M = {}

function M.guardar_sesion()
  local callback = function(input)
    if input then
      vim.cmd("PossessionSave " .. input)
    end
  end

  vim.ui.input({ prompt = "Ingrese el nombre de la sesión: " }, callback)
end

return M
