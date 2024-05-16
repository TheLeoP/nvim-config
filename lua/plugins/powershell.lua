return {
  "TheLeoP/powershell.nvim",
  dev = true,
  ---@type powershell.user_config
  opts = {
    capabilities = require("personal.config.lsp").capabilities,
    bundle_path = vim.fs.normalize(require("personal.config.lsp").mason_root .. "powershell-editor-services"),
    init_options = {
      enableProfileLoading = false,
    },
    settings = {
      enableProfileLoading = false,
    },
  },
}
