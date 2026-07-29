---@module "lspconfig"
---@type vim.lsp.Config
return {
  ---@type lspconfig.settings.yamlls
  settings = {
    yaml = {
      schemaStore = {
        enable = false,
        url = "",
      },
      schemas = require("schemastore").yaml.schemas(),
    },
  },
}
