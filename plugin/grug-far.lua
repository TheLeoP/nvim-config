vim.pack.add { "https://github.com/MagicDuck/grug-far.nvim" }

require("grug-far").setup {
  engine = "astgrep",
  engines = {
    astgrep = {
      path = "ast-grep",
    },
  },
}

vim.keymap.set("n", "<leader>fa", "<cmd>GrugFar<cr>")
