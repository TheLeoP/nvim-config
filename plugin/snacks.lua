vim.pack.add { "https://github.com/folke/snacks.nvim" }
require("snacks").setup {
  bigfile = {
    enabled = true,
  },
  profiler = {
    filter_mod = {
      ["^vim%."] = true,
    },
  },
}
