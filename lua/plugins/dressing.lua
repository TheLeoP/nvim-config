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
    },
  },
}
