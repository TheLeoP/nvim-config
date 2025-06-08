return {
  "smjonas/live-command.nvim",
  opts = {
    command_name = "P",
  },
  config = function(_, opts)
    require("live-command").setup(opts)
  end,
}
