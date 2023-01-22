vim.api.nvim_set_hl(0, "DiagnosticHint", { link = "GruvboxFg2" })
vim.api.nvim_set_hl(0, "DiagnosticSignHint", { link = "GruvboxFg2" })
vim.api.nvim_set_hl(0, "DiagnosticFloatingHint", { link = "GruvboxFg2" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "#d5c4a1" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { link = "GruvboxFg2" })

local highlight = vim.api.nvim_get_hl_by_name("Operator", true)
highlight.italic = false
vim.api.nvim_set_hl(0, "Operator", highlight)
