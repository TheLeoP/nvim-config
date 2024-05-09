return {
  "linguini1/pulse.nvim",
  opts = {},
  config = function(_, opts)
    local pulse = require "pulse"
    pulse.setup(opts)
    pulse.add("break", {
      interval = 20,
      message = "Take a break.",
      enabled = true,
    })
  end,
}
