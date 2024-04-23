return {
  "pwntester/octo.nvim",
  dependencies = {
    "plenary.nvim",
    "fzf-lua",
    "nvim-web-devicons",
  },
  opts = {
    use_local_fs = true,
    picker = "fzf-lua",
    suppress_missing_scope = {
      projects_v2 = true,
    },
  },
}
