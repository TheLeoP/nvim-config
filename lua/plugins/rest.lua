return {
  "rest-nvim/rest.nvim",
  config = function()
    require("rest-nvim").setup {
      keybinds = {
        { "<leader>ur", "<cmd>Rest run<cr>", "Run request under the cursor" },
        { "<leader>ul", "<cmd>Rest run last<cr>", "Re-run latest request" },
      },
    }
  end,
}
