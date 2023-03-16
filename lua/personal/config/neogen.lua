local neogen = require "neogen"
neogen.setup {}
vim.keymap.set("n", "<leader>gf", "<cmd>Neogen func<cr>")
vim.keymap.set("n", "<leader>gF", "<cmd>Neogen file<cr>")
vim.keymap.set("n", "<leader>gc", "<cmd>Neogen class<cr>")
vim.keymap.set("n", "<leader>gt", "<cmd>Neogen type<cr>")
