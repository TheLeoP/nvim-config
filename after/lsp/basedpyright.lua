---@module "lspconfig"
---@type vim.lsp.Config
return {
  ---@type lspconfig.settings.basedpyright
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
      },
    },
  },
}
