return {
  "mason-org/mason-lspconfig.nvim",
  dependencies = { "mason.nvim" },
  ---@module 'mason-lspconfig'
  ---@type MasonLspconfigSettings
  opts = {
    ensure_installed = { "jdtls" },
    automatic_installation = true,
    automatic_enable = false,
  },
}
