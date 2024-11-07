return {
  "linguini1/pulse.nvim",
  opts = {},
  cond = not vim.g.started_by_firenvim,
  config = function(_, opts)
    local pulse = require "pulse"
    pulse.setup(opts)
    pulse.add("break", {
      interval = 60,
      cb = function()
        local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
        vim.notify("Toma un descanso, LPM >>>>>>>>>>>>>>>>>>>>>:c", vim.log.levels.ERROR, { title = "Descanso" })
        vim.api.nvim_set_hl(0, "Normal", { fg = "red", bg = "red" })
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.defer_fn(function() vim.api.nvim_set_hl(0, "Normal", normal_hl) end, 2000)
      end,
    })
  end,
}
