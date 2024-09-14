return {
  "tpope/vim-fugitive",
  config = function()
    vim.keymap.set("n", "g<cr>", "<cmd>Git<cr>")
    vim.keymap.set("n", "g<space>", ":Git ")
  end,
  dependencies = { "tpope/vim-rhubarb" },
}
