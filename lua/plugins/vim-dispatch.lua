return {
  "tpope/vim-dispatch",
  config = function()
    -- TODO: replace this with overseer
    vim.keymap.set("n", "¿<cr>", "<cmd>Dispatch<cr>")
    vim.keymap.set("n", "¿<space>", ":Dispatch<space>")
    vim.keymap.set("n", "¿!", ":Dispatch!<space>")
    vim.keymap.set("n", "¿?", "<cmd>FocusDispatch<cr>")
  end,
}
