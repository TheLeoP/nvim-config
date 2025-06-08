vim.keymap.set("n", "<leader>P", function()
  require("powershell").toggle_term()
end)
vim.keymap.set({ "n", "x" }, "<leader>E", function()
  require("powershell").eval()
end)

vim.bo.iskeyword = vim.bo.iskeyword .. ",$"
