local M = {}

M.get_last_terminal = function()
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

M.visual_ejecutar_en_terminal = function()
  vim.cmd('normal yy')
  local comando = vim.fn.getreg('"')

  if vim.fn.has('win32') == 1 then
    comando = comando:gsub("\n", "\r")
  end

  local term_chan = M.get_last_terminal()

  vim.api.nvim_chan_send(term_chan, comando)
end

return M
