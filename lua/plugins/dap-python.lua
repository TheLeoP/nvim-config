local is_windows = vim.fn.has "win32" == 1

return {
  "mfussenegger/nvim-dap-python",
  config = function()
    ---@type string
    local mason_root = vim.fn.stdpath "data" .. "/mason/packages/"

    local tail = not is_windows and "debugpy/venv/bin/python" or "debugpy/venv/Scripts/python.exe"
    require("dap-python").setup(mason_root .. tail)
  end,
}
