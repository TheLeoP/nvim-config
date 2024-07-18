return {
  "stevearc/dressing.nvim",
  dependencies = {
    "fzf-lua",
  },
  opts = {
    input = {
      insert_only = false,
      start_in_insert = true,
      border = "single",
      win_options = {
        winblend = 0,
      },
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
          return string.format("%s\t[%s]", title, client.name)
        end,
      },
    },
  },
}
