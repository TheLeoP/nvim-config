return {
  "nvim-treesitter/nvim-treesitter-context",
  cond = not vim.g.started_by_firenvim,
  opts = {
    max_lines = 4,
    multiline_threshold = 1,
    min_window_height = 20,
  },
}
