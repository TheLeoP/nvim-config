return {
  "MagicDuck/grug-far.nvim",
  ---@type GrugFarOptionsOverride
  opts = {
    engine = "astgrep",
    engines = {
      astgrep = {
        path = "ast-grep",
      },
    },
  },
  config = function(_, opts)
    require("grug-far").setup(opts)

    vim.keymap.set("n", "<leader>fa", "<cmd>GrugFar<cr>")
  end,
}
