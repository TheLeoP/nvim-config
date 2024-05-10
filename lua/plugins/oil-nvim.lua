return {
  "stevearc/oil.nvim",
  opts = {
    skip_confirm_for_simple_edits = true,
    delete_to_trash = true,
    lsp_file_methods = {
      autosave_changes = "unmodified",
    },
    cleanup_delay_ms = false,
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
      ["<leader>cd"] = "actions.tcd",
      ["gt"] = "actions.toggle_trash",
      ["<leader>y"] = {
        callback = function()
          local oil = require "oil"
          local entry = oil.get_cursor_entry()
          local dir = oil.get_current_dir()
          if not entry or not dir then return vim.notify("Current entry has no dir or no name", vim.log.levels.WARN) end
          local path = dir .. entry.name
          vim.fn.setreg("+", path, 'V"')
        end,
        mode = "n",
        desc = "Copy path under cursor to clipboard",
      },
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
    vim.keymap.ste("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
  end,
  dependencies = { "nvim-tree/nvim-web-devicons" },
}
