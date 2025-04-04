return {
  "MeanderingProgrammer/render-markdown.nvim",
  ---@type render.md.UserConfig
  opts = {
    file_types = { "markdown", "rmd" },
    code = {
      sign = false,
    },
    heading = {
      sign = false,
      icons = {},
    },
    bullet = {
      enabled = false,
    },
    render_modes = { "n", "i", "ic", "ix" },
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)
    -- TODO: check if it has a blink.cmp integration
  end,
}
