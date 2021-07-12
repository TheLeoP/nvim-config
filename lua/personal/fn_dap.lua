local util = require('jdtls.util')
local api = vim.api

local iniciar_vimspector_java = function(puerto)
  local tabla = {
    AdapterPort = puerto
  }
  vim.fn['vimspector#LaunchWithSettings'](tabla)
end

local M = {}

M.iniciar_debug_java = function()
  -- inicio en una terminal el debugger de gradle
  api.nvim_command('botright vsplit new')
  api.nvim_command('terminal gradle run --debug-jvm')
  api.nvim_command('hide')

  util.execute_command({command = 'vscode.java.startDebugSession'}, function(err0, puerto)
    assert(not err0, vim.inspect(err0))
    iniciar_vimspector_java(puerto)
  end)
end


return M
