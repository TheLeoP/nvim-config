vim.pack.add { "https://github.com/mistweaverco/kulala.nvim" }
local kulala = require "kulala"
kulala.setup {}
vim.keymap.set("n", "[k", function()
  kulala.jump_prev()
end)
vim.keymap.set("n", "]k", function()
  kulala.jump_next()
end)
vim.keymap.set("n", "<leader>kr", function()
  kulala.run()
end)
vim.keymap.set("n", "<leader>kt", function()
  kulala.toggle_view()
end)
