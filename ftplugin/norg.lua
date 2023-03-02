vim.wo.spell = true
vim.bo.spelllang = "es,en"
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true
vim.wo.colorcolumn = 0
vim.wo.conceallevel = 3

vim.b[0].undo_ftplugin = "setlocal nospell nowrap nolinebreak nobreakindent conceallevel=0"

vim.keymap.set("n", "<leader>sc", "z=", { buffer = true })
vim.keymap.set("n", "<leader>sg", "zg", { buffer = true })
vim.keymap.set("n", "<leader>sug", "zug", { buffer = true })
vim.keymap.set("n", "<leader>sw", "zw", { buffer = true })
vim.keymap.set("n", "<leader>suw", "zuw", { buffer = true })

vim.keymap.set("n", "j", "v:count ? 'j' : 'gj'", { buffer = true, expr = true })
vim.keymap.set("n", "k", "v:count ? 'k' : 'gk'", { buffer = true, expr = true })
vim.keymap.set("n", "gj", "j", { buffer = true })
vim.keymap.set("n", "gk", "k", { buffer = true })