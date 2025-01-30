local keymap = vim.keymap

return {
  "aaronik/treewalker.nvim",
  config = function(_, opts)
    if not vim.tbl_isempty(opts) then require("treewalker").setup(opts) end

    keymap.set("n", "<up>", "<cmd>Treewalker Up<cr>", { desc = "AST UP" })
    keymap.set("n", "<down>", "<cmd>Treewalker Down<cr>", { desc = "AST DOWN" })
    keymap.set("n", "<left>", "<cmd>Treewalker Left<cr>", { desc = "AST LEFT" })
    keymap.set("n", "<right>", "<cmd>Treewalker Right<cr>", { desc = "AST RIGHT" })

    keymap.set("n", "<c-up>", "<cmd>Treewalker SwapUp<cr>", { desc = "AST SWAP UP" })
    keymap.set("n", "<c-down>", "<cmd>Treewalker SwapDown<cr>", { desc = "AST SWAP DOWN" })
    keymap.set("n", "<c-left>", "<cmd>Treewalker SwapLeft<cr>", { desc = "AST SWAP LEFT" })
    keymap.set("n", "<c-right>", "<cmd>Treewalker SwapRight<cr>", { desc = "AST SWAP RIGHT" })
  end,
}
