vim.api.nvim_set_hl(0, "DiagnosticHint", { link = "GruvboxFg2" })
vim.api.nvim_set_hl(0, "DiagnosticSignHint", { link = "GruvboxFg2" })
vim.api.nvim_set_hl(0, "DiagnosticFloatingHint", { link = "GruvboxFg2" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "#d5c4a1" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { link = "GruvboxFg2" })

local links = {
  ["@lsp.type.namespace"] = "@namespace",
  ["@lsp.type.type"] = "@type",
  ["@lsp.type.class"] = "@type",
  ["@lsp.type.enum"] = "@type",
  ["@lsp.type.interface"] = "@type",
  ["@lsp.type.struct"] = "@structure",
  ["@lsp.type.parameter"] = "@parameter",
  ["@lsp.type.variable"] = "@variable",
  ["@lsp.type.property"] = "@property",
  ["@lsp.type.enumMember"] = "@constant",
  ["@lsp.type.function"] = "@function",
  ["@lsp.type.method"] = "@method",
  ["@lsp.type.macro"] = "@macro",
  ["@lsp.type.decorator"] = "@function",
  ["@lsp.mod.defaultLibrary"] = "@function.builtin",
  ["@lsp.typemod.function.defaultLibrary"] = "@function.builtin",
  ["@lsp.typemod.variable.defaultLibrary"] = "@variable.builtin",
}
for newgroup, oldgroup in pairs(links) do
  vim.api.nvim_set_hl(0, newgroup, { link = oldgroup, default = true })
end
