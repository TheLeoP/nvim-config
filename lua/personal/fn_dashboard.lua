local M = {}

function M.guardar_sesion()
	local callback = function(input)
		if input then
			vim.cmd("SessionSave " .. input)
		end
	end

	vim.ui.input({ prompt = "Ingrese el nombre de la sesión: " }, callback)
end

function M.cargar_sesion()
	local callback = function(input)
		if input then
			vim.cmd("SessionLoad " .. input)
		end
	end

	vim.ui.input({ prompt = "Ingrese el nombre de la sesión: " }, callback)
end

return M
