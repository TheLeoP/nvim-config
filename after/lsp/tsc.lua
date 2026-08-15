---@module "lspconfig"
---@type vim.lsp.Config
return {
  cmd = function(dispatchers)
    -- TODO: remove when I can move all of my projectst to Typescript 7
    return vim.lsp.rpc.start({ "tsgo", "--lsp", "--stdio" }, dispatchers)
  end,
}
