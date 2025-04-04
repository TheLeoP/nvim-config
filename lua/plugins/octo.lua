return {
  "pwntester/octo.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "fzf-lua",
    "nvim-web-devicons",
  },
  opts = {
    use_local_fs = true,
    picker = "fzf-lua",
    picker_config = {
      use_emojis = true,
    },
    -- NOTE: requires both read:project and project scopes
    default_to_projects_v2 = true,
  },
  config = function(_, opts)
    require("octo").setup(opts)
    vim.treesitter.language.register("markdown", "octo")
  end,
}
