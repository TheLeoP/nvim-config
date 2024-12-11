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

    Snacks.scroll.enable()

    vim.api.nvim_create_user_command("Dim", function()
      if Snacks.dim.enabled then
        Snacks.dim.disable()
      else
        Snacks.dim.enable()
      end
    end, {})
  end,
}
