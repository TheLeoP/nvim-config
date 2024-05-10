local is_windows = vim.fn.has "win32" == 1

return {
  "mxsdev/nvim-dap-vscode-js",
  lazy = true,
  dependencies = {
    {
      "microsoft/vscode-js-debug",
      version = "1.x",
      build = "npm i && npm run compile vsDebugServerBundle &&"
        .. (is_windows and "(if exist out\\ rd /s /q out)" or "rm -rf out")
        .. "&&"
        .. (is_windows and "move dist out" or "mv dist out"),
    },
  },
  config = function()
    require("dap-vscode-js").setup {
      debugger_path = vim.fn.stdpath "data" .. "/lazy/vscode-js-debug",
      adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
    }
  end,
}
