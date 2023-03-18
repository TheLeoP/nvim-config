return {
  {
    "vim-test/vim-test",
    keys = {
      { "<silent>", "<leader>pn", "<cmd>TestNearest<cr>", mode = "n" },
      { "<silent>", "<leader>pf", "<cmd>TestFile<cr>", mode = "n" },
      { "<silent>", "<leader>ps", "<cmd>TestSuite<cr>", mode = "n" },
      { "<silent>", "<leader>pl", "<cmd>TestLast<cr>", mode = "n" },
      { "<silent>", "<leader>pv", "<cmd>TestVisit<cr>", mode = "n" },
    },
    init = function()
      vim.g["test#java#runner"] = "gradletest"
      vim.g["test#strategy"] = "dispatch"
    end,
  },
}
