vim.pack.add {
  "https://github.com/tpope/vim-fugitive",
  "https://github.com/tpope/vim-rhubarb",
}

vim.keymap.set("n", "g<cr>", "<cmd>Git<cr>")
vim.keymap.set("n", "gl", "<cmd>Git log -50 --oneline<cr>")
vim.keymap.set("n", "g<space>", ":Git ")
