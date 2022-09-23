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

vim.cmd [[highlight IndentBlanklineChar guifg=#4f4f4f gui=nocombine]]
