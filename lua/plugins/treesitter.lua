return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "c",
      "lua",
      "luap",
      "printf",
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
      opts = {
        select = {
          lookahead = true,
        },
      },
      config = function(_, opts) require("nvim-treesitter-textobjects").setup(opts) end,
    },
    {
      "LiadOZ/nvim-dap-repl-highlights",
      opts = {},
    },
    {
      "nvim-treesitter/nvim-treesitter-context",
      cond = not vim.g.started_by_firenvim,
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
}
