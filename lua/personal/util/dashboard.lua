local a = require "plenary.async"

local M = {}

function M.guardar_sesion()
  local input = a.wrap(vim.ui.input, 2)
  a.void(function()
    local session = input { prompt = "Ingrese el nombre de la sesión: " }
    if session then
      vim.cmd.PossessionSave(session)
    end
  end)()
end

return M
