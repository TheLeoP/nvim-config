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
    picker_config = {
      use_emojis = true,
    },
    -- NOTE: using true shows a msg on startup since https://github.com/pwntester/octo.nvim/pull/667
    default_to_projects_v2 = false,
  },
  config = function(_, opts)
    require("octo").setup(opts)
    vim.treesitter.language.register("markdown", "octo")
  end,
}
