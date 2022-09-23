local dap = require "dap"

-- signs

vim.fn.sign_define("DapBreakpoint", { text = "⦿", texthl = "LspDiagnosticsSignError", linehl = "", numhl = "" })

-- configuration and adapters

dap.adapters.python = {
  type = "executable",
  command = "python",
  args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
  {
    -- The first three options are required by nvim-dap
    type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
    request = "launch",
    name = "Launch file",

    -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

    program = "${file}", -- This configuration will launch the current file if used.
    pythonPath = function()
      -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
      -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
      -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
      local cwd = vim.fn.getcwd()
      if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
        return cwd .. "/venv/bin/python"
      elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
        return cwd .. "/.venv/bin/python"
      else
        return "python"
      end
    end,
  },
}

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
      local val = tonumber(vim.fn.input "Port: ")
      return val
    end,
  },
}
