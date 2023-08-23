vim.b.dispatch = "gradle compileJava"
local ok, lsp = pcall(require, "personal.config.lsp")
if ok then
  lsp.jdtls_setup()
end
