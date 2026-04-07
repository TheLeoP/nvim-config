vim.pack.add { "https://github.com/nvim-treesitter/nvim-treesitter-context" }

require("treesitter-context").setup {
  max_lines = 4,
  multiline_threshold = 1,
  min_window_height = 20,
}
