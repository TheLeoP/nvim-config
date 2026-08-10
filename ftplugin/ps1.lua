vim.keymap.set("n", "<leader>lt", function()
  require("powershell").toggle_term()
end, { buffer = true })
vim.keymap.set("n", "<leader>ld", function()
  require("powershell").toggle_debug_term()
end, { buffer = true })

vim.keymap.set({ "n", "x" }, "g=", function()
  return require("powershell").eval_operator()
end, { buffer = true, expr = true })
vim.keymap.set({ "n" }, "g==", function()
  return require("powershell").eval_operator() .. "_"
end, { buffer = true, expr = true })

vim.bo.iskeyword = vim.bo.iskeyword .. ",$"
