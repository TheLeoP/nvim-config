require("indent_blankline").setup {
  char_list = { "|", "¦", "┆", "┊" },
  show_trailing_blankline_indent = false,
  filetype_exclude = {
    "lspinfo",
    "packer",
    "checkhealth",
    "help",
    "man",
    "",
    "dashboard",
  },
}

vim.api.nvim_set_hl(0, "IndentBlanklineChar", { fg = "#4f4f4f", nocombine = true })
