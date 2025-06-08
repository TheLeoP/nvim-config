local api = vim.api
local iter = vim.iter

local should_show_detail = false

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
        mode = "n",
        desc = "Refresh and dismiss notifications",
        callback = function()
          if not vim.bo.modified then require("oil.actions").refresh.callback() end
          vim.cmd.nohlsearch()
          vim.cmd.diffupdate()
          require("notify").dismiss { silent = true, pending = true }
          require("personal.util.general").clear_system_notifications()
          vim.cmd.normal { "\12", bang = true } -- ctrl-l
        end,
      },
      ["<leader>cd"] = { "actions.cd", opts = { scope = "tab", silent = true } },
      ["gt"] = "actions.toggle_trash",
      ["gd"] = {
        mode = "n",
        desc = "Toggle file detail view",
        callback = function()
          local set_columns = require("oil").set_columns

          should_show_detail = not should_show_detail
          if should_show_detail then
            set_columns {
              "icon",
              "permissions",
              { "size", highlight = "Comment" },
              { "mtime", format = "%Y-%m-%d %T", highlight = "Special" },
            }
          else
            set_columns { "icon" }
          end
        end,
      },
      ["<bs>"] = "actions.open_cwd",
      ["<leader>y"] = "actions.copy_entry_path",
      ["<leader>."] = "actions.open_cmdline",
      ["g\\"] = false,
      ["`"] = false,
      ["~"] = false,
      ["_"] = false,
    },
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name, _buf)
        return name == ".."
      end,
      sort = {
        { "name", "asc" },
      },
    },
  },
  config = function(_, opts)
    require("oil").setup(opts)
    vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })

    local group = api.nvim_create_augroup("oil-remove-buffer", {})
    api.nvim_create_autocmd("User", {
      pattern = "OilActionsPost",
      desc = "Remove buffer after file delete",
      group = group,
      ---@param opts _oil.autocmd_opts
      callback = function(opts)
        if opts.data.err then return end

        iter(opts.data.actions):each(
          ---@param action oil.Action
          function(action)
            if action.type ~= "delete" or action.entry_type ~= "file" then return end
            local posix_to_os_path = require("oil.fs").posix_to_os_path

            local _scheme, path = action.url:match "^(.*://)(.*)$"
            path = posix_to_os_path(path)

            local buf = vim.fn.bufnr(path)
            if buf == -1 then return end

            api.nvim_buf_delete(buf, { force = true })
          end
        )
      end,
    })
  end,
  dependencies = { "nvim-web-devicons" },
}
