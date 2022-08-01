local M = {}

function M.get_last_terminal()
	local terminal_channels = {}

	for _, channel in pairs(vim.api.nvim_list_chans()) do
		if channel["mode"] == "terminal" and channel["pty"] ~= "" then
			table.insert(terminal_channels, channel)
		end
	end

	table.sort(terminal_channels, function(left, right)
		return left["buffer"] < right["buffer"]
	end)

	return terminal_channels[1]["id"]
end

function M.visual_ejecutar_en_terminal()
	-- cierro el modo visual para tener guardados correctamente las marcas
	vim.cmd("normal ")

	-- par {columna, fila} donde columan es base 1 y fila es base 0
	local inicio = vim.api.nvim_buf_get_mark(0, "<")
	local fin = vim.api.nvim_buf_get_mark(0, ">")

	-- ya que el rango final no es inclusivo y el índice es base 1, se resta 1 al inicio
	local lineas = vim.api.nvim_buf_get_lines(0, inicio[1] - 1, fin[1], true)

	local fin_de_linea
	if vim.fn.has("win32") == 1 then
		fin_de_linea = "\r"
	else
		fin_de_linea = "\n"
	end

	local comandos = ""
	for _, comando in ipairs(lineas) do
		comandos = comandos .. comando .. fin_de_linea
	end

	local term_chan = M.get_last_terminal()

	vim.api.nvim_chan_send(term_chan, comandos)
end

function M.get_nombre_time_stamp()
	local nombre = os.date("%Y-%m-%d %H-%M-%S") .. ".md"
	return nombre
end

function M.get_nombre_input_o_timestamp(tipo)
	local prompt = string.format("Ingrese el nombre de %s: ", tipo)
	local nombre = vim.fn.input(prompt)
	if nombre == "" then
		nombre = M.get_nombre_time_stamp()
	end
	return nombre
end

function M.nuevo_autoregistro_emociones()
	local nombre_archivo = M.get_nombre_input_o_timestamp("el autoregistro")
	local path_archivo = vim.g.notas_emociones .. "/" .. nombre_archivo
	vim.cmd("e " .. path_archivo)
end

function M.nueva_nota_U()
	local callback = function(path)
		if path then
			local nombre = M.get_nombre_input_o_timestamp("la nota")
			local full_path = path .. "Apuntes/" .. nombre
			vim.cmd(string.format("e %s", full_path))
		else
			print("La entrada seleccionada no tiene path")
		end
	end

	require("personal.fn_telescope").seleccionar_materia(callback)
end

return M
