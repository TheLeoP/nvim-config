vim.pack.add { "https://github.com/uga-rosa/ccc.nvim" }

local ccc = require "ccc"
ccc.setup {
  inputs = {
    ccc.input.rgb,
    ccc.input.oklch,
  },
}
