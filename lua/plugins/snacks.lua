return {
  "folke/snacks.nvim",
  priority = 1000,
  ---@module "snacks"
  ---@type snacks.Config
  opts = {
    bigfile = {
      enabled = true,
    },
    profiler = {
      filter_mod = {
        ["^vim%."] = true,
      },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
  end,
}
