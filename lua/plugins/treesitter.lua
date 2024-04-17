return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "c",
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "query",
        "xml",
        "http",
        "json",
        "graphql",
      },
      sync_install = true,
      auto_install = true,
      ignore_install = {
        "thrift",
        "comment",
      },
      highlight = {
        enable = true, -- false will disable the whole extension
        disable = {
          "dashboard",
        },
      },
      indent = {
        enable = false,
      },
      playground = {
        enable = true,
      },
      autotag = {
        enable = true,
      },
    },
    config = function(_, opts)
      if vim.fn.has "win32" == 1 then require("nvim-treesitter.install").compilers = { "clang" } end
      require("nvim-treesitter.configs").setup(opts)
    end,
    dependencies = {
      {
        "folke/twilight.nvim",
        opts = {},
      },
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        opts = {},
      },
      {
        "nvim-treesitter/playground",
      },
      {
        "LiadOZ/nvim-dap-repl-highlights",
        opts = {},
      },
      {
        "nvim-treesitter/nvim-treesitter-context",
        opts = {
          max_lines = 4,
          multiline_threshold = 1,
          min_window_height = 20,
        },
      },
      {
        "windwp/nvim-ts-autotag",
        opts = {
          enable_close_on_slash = false,
        },
      },
    },
  },
}
