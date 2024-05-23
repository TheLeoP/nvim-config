return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  opts = {
    select = {
      lookahead = true,
    },
  },
  config = function(_, opts) require("nvim-treesitter-textobjects").setup(opts) end,
}
