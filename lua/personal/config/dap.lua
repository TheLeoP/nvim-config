local dap = require "dap"
local dapui = require "dapui"

-- signs

vim.fn.sign_define("DapBreakpoint", { text = "⦿", texthl = "LspDiagnosticsSignError", linehl = "", numhl = "" })

-- configuration and adapters

local mason_root = vim.fn.stdpath "data" .. "/mason/packages/"

require("dap-python").setup(mason_root .. "debugpy/venv/Scripts/pyton.exe")

dap.adapters.nlua = function(callback, config)
  callback {
    type = "server",
    host = config.host,
    port = config.port or 5005,
  }
end

dap.configurations.lua = {
  {
    type = "nlua",
    request = "attach",
    name = "nlua attach",
    host = "127.0.0.1",
    port = function()
      local val = tonumber(vim.fn.input { prompt = "Port: " })
      return val
    end,
  },
}

dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
  dap.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
  dap.close()
end
