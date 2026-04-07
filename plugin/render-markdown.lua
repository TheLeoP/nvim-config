vim.pack.add { "https://github.com/MeanderingProgrammer/render-markdown.nvim" }

require("render-markdown").setup {
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
  completions = { blink = { enabled = true } },
  overrides = { buftype = { ["nofile"] = { enabled = false } } },
}
