return {
  {
    "vim-test/vim-test",
    keys = {
      { "<leader>pn", "<cmd>TestNearest<cr>", mode = "n", silent = true },
      { "<leader>pf", "<cmd>TestFile<cr>", mode = "n", silent = true },
      { "<leader>ps", "<cmd>TestSuite<cr>", mode = "n", silent = true },
      { "<leader>pl", "<cmd>TestLast<cr>", mode = "n", silent = true },
      { "<leader>pv", "<cmd>TestVisit<cr>", mode = "n", silent = true },
    },
    init = function()
      vim.g["test#java#runner"] = "gradletest"
      vim.g["test#strategy"] = "dispatch"
    end,
  },
}
