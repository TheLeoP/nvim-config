vim.keymap.set("i", "<c-f>", "copilot#Accept()", { silent = true, expr = true })
vim.keymap.set("i", "<M-{>", vim.fn["copilot#Next"])
vim.keymap.set("i", "<M-}>", vim.fn["copilot#Previous"])
vim.keymap.set("i", "<M-'>", vim.fn["copilot#Suggest"])

vim.keymap.set("i", "<c-]>", vim.fn["copilot#Dismiss"])
vim.keymap.set("i", "", vim.fn["copilot#Dismiss"])
