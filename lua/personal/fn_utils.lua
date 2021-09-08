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
  local inicio = vim.api.nvim_buf_get_mark(0, '<')
  local fin = vim.api.nvim_buf_get_mark(0, '>')

  -- ya que el rango final no es inclusivo y el índice es base 1, se resta 1 al inicio
  local lineas = vim.api.nvim_buf_get_lines(0, inicio[1] - 1, fin[1], true)

  local fin_de_linea
  if vim.fn.has('win32') == 1 then
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

function M.crear_autoregistro_emociones()
  local nombre_archivo = os.date():gsub('[/:]', '-') .. '.md'
  local path_archivo = vim.g.notas_emociones .. '/' .. nombre_archivo
  vim.cmd('e ' .. path_archivo)
end

return M
