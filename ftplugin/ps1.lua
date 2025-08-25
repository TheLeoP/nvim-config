vim.keymap.set("n", "<leader>P", function()
  require("powershell").toggle_term()
end, { buffer = true })
vim.keymap.set({ "n", "x" }, "<leader>E", function()
  require("powershell").eval()
end, { buffer = true })

vim.bo.iskeyword = vim.bo.iskeyword .. ",$"
