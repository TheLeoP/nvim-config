return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "mason.nvim" },
  opts = {
    ensure_installed = { "jdtls" },
    automatic_installation = true,
  },
}
