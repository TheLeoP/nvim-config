return {
  "folke/which-key.nvim",
  ---@module "which-key"
  ---@type wk.Opts
  opts = {
    delay = 500,
    spec = {
      { "<leader>a", group = "ref[a]ctor" },
      {
        "<leader>d",
        function() require("which-key").show { keys = "<leader>d", loop = true } end,
        group = "[d]ebug",
      },
      { "<leader>f", group = "[f]ind" },
      { "<leader>g", group = "[g]enerate" },
      { "<leader>t", group = "[t]oggle" },
      { "<leader>k", group = "[k]ulala" },
      { "<leader>h", group = "gitsigns" },
      { "<leader>o", group = "[o]verseer" },
      { "<leader>p", group = "debug [p]rint" },
      { "<leader>v", group = "mini.[v]isits" },
    },
    expand = function(node) return not node.desc end,
    plugins = {
      spelling = { enabled = false },
      presets = {
        operators = false,
        motions = false,
        text_objects = false,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },
  },
}
