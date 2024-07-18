return {
  "tpope/vim-fugitive",
  config = function()
    vim.api.nvim_create_user_command("Browse", function(args) vim.ui.open(args.args) end, {
      desc = "Enables using GBrowse without netrw",
      force = true,
      nargs = 1,
    })
    vim.keymap.set("n", "g<cr>", "<cmd>Git<cr>")
  end,
  dependencies = { "tpope/vim-rhubarb" },
}
