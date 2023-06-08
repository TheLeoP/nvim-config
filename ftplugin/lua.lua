vim.keymap.set("n", "<F5>", function()
  require("osv").launch { port = 8086 }
end)
vim.treesitter.start()
