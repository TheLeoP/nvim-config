return {
  {
    "nvim-treesitter/nvim-treesitter",
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
      autotag = {
        enable = true,
      },
    },
    config = function(_, opts)
      if vim.fn.has "win32" == 1 then require("nvim-treesitter.install").compilers = { "clang" } end
      require("nvim-treesitter.configs").setup(opts)
      vim.treesitter.language.register("markdown", "octo")
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
        config = function(_, opts)
          require("nvim-treesitter-textobjects").setup(opts)

          vim.keymap.set(
            { "x", "o" },
            "<F4>",
            function() require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects") end
          )
          vim.keymap.set(
            { "x", "o" },
            "<F5>",
            function() require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects") end
          )
        end,
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
