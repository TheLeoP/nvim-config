return {
  "danymat/neogen",
  opts = {},
  config = function(_, opts)
    require("neogen").setup(opts)
    vim.keymap.set("n", "<leader>gf", "<cmd>Neogen func<cr>")
    vim.keymap.set("n", "<leader>gF", "<cmd>Neogen file<cr>")
    vim.keymap.set("n", "<leader>gc", "<cmd>Neogen class<cr>")
    vim.keymap.set("n", "<leader>gt", "<cmd>Neogen type<cr>")
  end,
}
