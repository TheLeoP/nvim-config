vim.api.nvim_set_hl(0, "DiagnosticHint", { link = "GruvboxFg2" })
vim.api.nvim_set_hl(0, "DiagnosticSignHint", { link = "GruvboxFg2" })
vim.api.nvim_set_hl(0, "DiagnosticFloatingHint", { link = "GruvboxFg2" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "#d5c4a1" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { link = "GruvboxFg2" })

vim.api.nvim_set_hl(0, "FloatBorder", { link = "NormalFloat" })

vim.api.nvim_set_hl(0, "@none", { bg = "NONE", fg = "NONE" })
vim.api.nvim_set_hl(0, "@text.strong", { bold = true })
vim.api.nvim_set_hl(0, "@text.emphasis", { italic = true })
vim.api.nvim_set_hl(0, "@text.underline", { underline = true })
vim.api.nvim_set_hl(0, "@text.strike", { strikethrough = true })

-- treesitter and LSP links to default groups
local links = {
  ["@comment"] = "Comment",
  ["@preproc"] = "PreProc",
  ["@define"] = "Define",
  ["@operator"] = "Operator",

  ["@punctuation.delimiter"] = "Delimiter",
  ["@punctuation.bracket"] = "Delimiter",
  ["@punctuation.special"] = "Delimiter",

  ["@string"] = "String",
  ["@string.regex"] = "String",
  ["@string.escape"] = "SpecialChar",
  ["@string.special"] = "SpecialChar",

  ["@character"] = "Character",
  ["@character.special"] = "SpecialChar",

  ["@boolean"] = "Boolean",
  ["@number"] = "Number",
  ["@float"] = "Float",

  ["@function"] = "Function",
  ["@function.call"] = "Function",
  ["@function.builtin"] = "Special",
  ["@function.macro"] = "Macro",

  ["@method"] = "Function",
  ["@method.call"] = "Function",

  ["@constructor"] = "Special",
  ["@parameter"] = "Identifier",

  ["@keyword"] = "Keyword",
  ["@keyword.function"] = "Keyword",
  ["@keyword.operator"] = "Keyword",
  ["@keyword.return"] = "Keyword",

  ["@conditional"] = "Conditional",
  ["@repeat"] = "Repeat",
  ["@debug"] = "Debug",
  ["@label"] = "Label",
  ["@include"] = "Include",
  ["@exception"] = "Exception",

  ["@type"] = "Type",
  ["@type.builtin"] = "Type",
  ["@type.qualifier"] = "Type",
  ["@type.definition"] = "Typedef",

  ["@storageclass"] = "StorageClass",
  ["@attribute"] = "PreProc",
  ["@field"] = "Identifier",
  ["@property"] = "Identifier",

  ["@variable"] = "Normal",
  ["@variable.builtin"] = "Special",

  ["@constant"] = "Constant",
  ["@constant.builtin"] = "Special",
  ["@constant.macro"] = "Define",

  ["@namespace"] = "Include",
  ["@symbol"] = "Identifier",

  ["@text"] = "Normal",
  ["@text.title"] = "Title",
  ["@text.literal"] = "String",
  ["@text.uri"] = "Underlined",
  ["@text.math"] = "Special",
  ["@text.environment"] = "Macro",
  ["@text.environment.name"] = "Type",
  ["@text.reference"] = "Constant",

  ["@text.todo"] = "Todo",
  ["@text.note"] = "SpecialComment",
  ["@text.warning"] = "WarningMsg",
  ["@text.danger"] = "ErrorMsg",

  ["@tag"] = "Tag",
  ["@tag.attribute"] = "Identifier",
  ["@tag.delimiter"] = "Delimiter",
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
  ["@lsp.mod.readonly"] = "@constant",
  ["@lsp.typemod.function.defaultLibrary"] = "@function.builtin",
  ["@lsp.typemod.variable.defaultLibrary"] = "@variable.builtin",
  ["@lsp.typemod.variable.readonly"] = "@constant",
}

for newgroup, oldgroup in pairs(links) do
  vim.api.nvim_set_hl(0, newgroup, { link = oldgroup, default = true })
end
