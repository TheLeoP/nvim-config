return {
  "stevearc/oil.nvim",
  opts = {
    skip_confirm_for_simple_edits = true,
    delete_to_trash = true,
    lsp_file_methods = {
      autosave_changes = "unmodified",
    },
    cleanup_delay_ms = false,
    watch_for_changes = true,
    keymaps = {
      ["<C-l>"] = {
        callback = function()
          require("oil.actions").refresh.callback()
          vim.cmd.nohlsearch()
          vim.cmd.diffupdate()
          require("notify").dismiss { silent = true, pending = true }
          vim.cmd.normal { "\12", bang = true } -- ctrl-l
        end,
        mode = "n",
        desc = "Refresh and dismiss notifications",
      },
      ["<leader>cd"] = { "actions.cd", opts = { scope = "tab", silent = true } },
      ["gt"] = "actions.toggle_trash",
      ["<leader>y"] = "actions.copy_entry_path",
      ["<leader>:"] = "actions.open_cmdline",
      ["g\\"] = false,
      ["`"] = false,
      ["~"] = false,
    },
    view_options = {
      show_hidden = true,
    },
  },
  config = function(_, opts)
    require("oil").setup(opts)
    vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
  end,
  dependencies = { "nvim-web-devicons" },
}
