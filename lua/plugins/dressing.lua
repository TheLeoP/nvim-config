return {
  "stevearc/dressing.nvim",
  dependencies = {
    "fzf-lua",
  },
  opts = {
    input = {
      insert_only = false,
      start_mode = "insert",
      border = "single",
      win_options = {
        winblend = 0,
      },
      get_config = function(opts)
        if opts.prompt == "cmd: " then -- I use this to run shell commands
          return {
            insert_only = false,
            start_mode = "insert",
            border = "single",
            relative = "editor",
            prefer_width = 0.90,
            max_width = 0.90,
            min_width = 0.90,
            win_options = {
              winblend = 0,
            },
          }
        end
      end,
    },
    select = {
      fzf_lua = {
        winopts = {
          height = 0.5,
          width = 0.5,
        },
      },
      backend = { "fzf_lua", "nui", "builtin" },
      get_config = function(opts)
        if opts.kind == "codeaction" then
          return {
            fzf_lua = {
              winopts = {
                height = 0.9,
                width = 0.9,
              },
            },
          }
        end
      end,
      format_item_override = {
        codeaction = function(action_tuple)
          local title = action_tuple.action.title
          local client = vim.lsp.get_client_by_id(action_tuple.ctx.client_id)
          return ("%s\t[%s]"):format(title, client.name)
        end,
      },
    },
  },
}
