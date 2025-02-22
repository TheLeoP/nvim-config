local keymap = vim.keymap

return {
  "tpope/vim-rsi",
  config = function()
    -- Only use command mode keymaps
    keymap.del("i", "<C-a>")
    keymap.del("i", "<C-x><C-a>")
    keymap.del("i", "<C-b>")
    keymap.del("i", "<C-d>")
    keymap.del("i", "<C-e>")
    keymap.del("i", "<C-f>")
    keymap.del("i", "<M-BS>")
    keymap.del("i", "<M-b>")
    keymap.del("i", "<M-d>")
    keymap.del("i", "<M-f>")
    keymap.del("i", "<M-n>")
    keymap.del("i", "<M-p>")
  end,
}
