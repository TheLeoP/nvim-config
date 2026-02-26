vim.keymap.set("n", "<leader>lt", function()
  require("powershell").toggle_term()
end, { buffer = true })
vim.keymap.set("n", "<leader>ld", function()
  require("powershell").toggle_debug_term()
end, { buffer = true })
vim.keymap.set({ "n", "x" }, "<leader>le", function()
  require("powershell").eval()
end, { buffer = true })

vim.bo.iskeyword = vim.bo.iskeyword .. ",$"
