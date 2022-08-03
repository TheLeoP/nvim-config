local devicons = require("nvim-web-devicons")
local navic = require("nvim-navic")

local custom_providers = {
	file = function()
		local filename = " " .. vim.fn.expand("%:t", false, false)
		local extension = vim.fn.expand("%:e", false, false)
		local iconStr, name = devicons.get_icon(filename, extension)
		local fg = name and vim.fn.synIDattr(vim.fn.hlID(name), "fg") or "white"

		local icon = {
			str = iconStr,
			hl = {
				fg = fg,
				bg = "bg",
			},
		}
		return filename, icon
	end,
	cwd = function()
		return vim.fn.getcwd()
	end,
	tags = function()
		return vim.fn["gutentags#statusline"]()
	end,
	navic = function(_, opts)
		return navic.get_location(opts)
	end,
}

local components = {
	active = {
		{
			{
				provider = "vi_mode",
				hl = function()
					return {
						name = require("feline.providers.vi_mode").get_mode_highlight_name(),
						fg = require("feline.providers.vi_mode").get_mode_color(),
						style = "bold",
					}
				end,
				left_sep = " ",
				right_sep = " ",
				icon = "",
			},
			{
				provider = "git_branch",
				right_sep = " ",
			},
			{
				provider = "cwd",
				right_sep = {
					str = " | ",
					hl = {
						fg = "white",
						bg = "bg",
					},
				},
			},
			{
				provider = "file",
			},
		},
		{
			{
				provider = "tags",
				left_sep = " ",
				right_sep = " ",
			},
			{
				provider = "navic",
				enabled = navic.is_available,
				left_sep = " ",
				right_sep = " ",
			},
			{
				provider = "file_type",
				left_sep = " ",
				right_sep = " ",
			},
		},
	},
}

require("feline").setup({
	components = components,
	custom_providers = custom_providers,
})
