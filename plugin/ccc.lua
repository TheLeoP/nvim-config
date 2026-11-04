vim.pack.add { "https://github.com/uga-rosa/ccc.nvim" }

local ccc = require "ccc"
ccc.setup {
  alpha_show = "hide",
  inputs = {
    ccc.input.oklch,
    ccc.input.rgb,
  },
}
