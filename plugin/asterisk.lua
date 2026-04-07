vim.g["asterisk#keeppos"] = 1

vim.pack.add { "https://github.com/haya14busa/vim-asterisk" }

vim.keymap.set({ "n", "x", "o" }, "*", "<Plug>(asterisk-*)")
vim.keymap.set({ "n", "x", "o" }, "#", "<Plug>(asterisk-#)")
vim.keymap.set({ "n", "x", "o" }, "g*", "<Plug>(asterisk-g*)")
vim.keymap.set({ "n", "x", "o" }, "g#", "<Plug>(asterisk-g#)")
vim.keymap.set({ "n", "x", "o" }, "z*", "<Plug>(asterisk-z*)")
vim.keymap.set({ "n", "x", "o" }, "gz*", "<Plug>(asterisk-gz*)")
vim.keymap.set({ "n", "x", "o" }, "z#", "<Plug>(asterisk-z#)")
vim.keymap.set({ "n", "x", "o" }, "gz#", "<Plug>(asterisk-gz#)")
