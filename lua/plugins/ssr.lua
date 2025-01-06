return {
  "cshuaimin/ssr.nvim",
  module = "ssr",
  opts = function()
    local factor = 0.9
    local max_height = math.floor(vim.o.lines * factor)
    return {
      border = "rounded",
      max_height = max_height,
      adjust_window = true,
      -- these are mostly defautls but are here for reference
      keymaps = {
        close = "q",
        next_match = "n",
        prev_match = "N",
        replace_confirm = "<cr>",
        replace_all = "<c-cr>",
      },
    }
  end,
  config = function(_, opts)
    require("ssr").setup(opts)

    vim.keymap.set({ "n", "x" }, "<leader>l", function() require("ssr").open() end, { desc = "Open SSR" })
  end,
}
