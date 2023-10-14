-- :fennel:1697246935
local function search_nvim_config()
  local builtin = require("telescope.builtin")
  return builtin.find_files({prompt_title = "< Nvim config >", cwd = vim.fn.stdpath("config")})
end
vim.keymap.set({"n"}, "<leader>fi", search_nvim_config, {desc = "Fuzzy search files in nvim config", silent = true})
local function rg_nvim_config()
  local telescope = require("telescope")
  return telescope.extensions.live_grep_args.live_grep_args({prompt_title = "< Rg nvim_config >", cwd = vim.fn.stdpath("config")})
end
return vim.keymap.set({"n"}, "<leader>fI", rg_nvim_config, {desc = "Rg in nvim config", silent = true})