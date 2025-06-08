vim.keymap.set("n", "<<", function()
  pcall(vim.cmd.colder)
end, { buffer = true })
vim.keymap.set("n", ">>", function()
  pcall(vim.cmd.cnewer)
end, { buffer = true })

vim.cmd.packadd "cfilter"
