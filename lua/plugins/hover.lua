return {
  "lewis6991/hover.nvim",
  config = function()
    require("hover").setup {
      init = function()
        require "hover.providers.lsp"
        require "hover.providers.gh"
        require "hover.providers.gh_user"
        require "hover.providers.dap"
        require "hover.providers.man"
        require "hover.providers.dictionary"
      end,
      preview_opts = {
        border = "none",
      },
      title = true,
      preview_window = true,
    }

    -- Setup keymaps
    vim.keymap.set("n", "K", require("hover").hover, { desc = "hover.nvim" })
    vim.keymap.set("n", "gK", require("hover").hover_select, { desc = "hover.nvim (select)" })
    vim.keymap.set(
      "n",
      "<C-p>",
      function() require("hover").hover_switch "previous" end,
      { desc = "hover.nvim (previous source)" }
    )
    vim.keymap.set(
      "n",
      "<C-n>",
      function() require("hover").hover_switch "next" end,
      { desc = "hover.nvim (next source)" }
    )
  end,
}
