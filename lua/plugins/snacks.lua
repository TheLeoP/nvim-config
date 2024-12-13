return {
  "folke/snacks.nvim",
  priority = 1000,
  ---@module "snacks"
  ---@type snacks.Config
  opts = {
    bigfile = {
      enabled = true,
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    vim.keymap.set("n", "<leader>tm", function()
      if Snacks.dim.enabled then
        Snacks.dim.disable()
      else
        Snacks.dim.enable()
      end
    end)
  end,
}
