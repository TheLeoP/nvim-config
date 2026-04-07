vim.pack.add { "https://github.com/stevearc/quicker.nvim" }

require("quicker").setup {
  opts = {
    number = true,
    relativenumber = true,
  },
  highlight = {
    load_buffers = false,
  },
  trim_leading_whitespace = "all",
  keys = {
    {
      "<Right>",
      function()
        require("quicker").expand { before = 2, after = 2, add_to_existing = true }
      end,
      desc = "Expand quickfix context",
    },
    {
      "<Left>",
      function()
        require("quicker").collapse()
      end,
      desc = "Collapse quickfix context",
    },
  },
}
vim.api.nvim_set_hl(0, "QuickFixFilenameInvalid", { link = "QuickFixFilename" })
