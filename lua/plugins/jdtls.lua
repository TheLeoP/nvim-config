return {
  "mfussenegger/nvim-jdtls",
  dependencies = {
    "nvim-dap",
    "blink.cmp",
  },
  config = function()
    vim.lsp.enable "jdtls"
  end,
}
