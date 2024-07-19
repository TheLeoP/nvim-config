return {
  "tpope/vim-fugitive",
  config = function() vim.keymap.set("n", "g<cr>", "<cmd>Git<cr>") end,
  dependencies = { "tpope/vim-rhubarb" },
}
