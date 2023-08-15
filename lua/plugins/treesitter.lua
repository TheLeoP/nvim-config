local treesitter_dev = false

return {
  {
    "nvim-treesitter/nvim-treesitter",
    dev = treesitter_dev,
    build = ":TSUpdate",
    opts = {
      ensure_installed = "all",
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
      context_commentstring = {
        enable = true,
      },
      playground = {
        enable = true,
      },
      textobjects = {
        enable = true,
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]m"] = "@function.outer",
            ["]]"] = { query = "@class.outer", desc = "Next class start" },
            -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
            -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
            ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
          },
          goto_next_end = {
            ["]M"] = "@function.outer",
            ["]["] = "@class.outer",
          },
          goto_previous_start = {
            ["[m"] = "@function.outer",
            ["[["] = "@class.outer",
          },
          goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[]"] = "@class.outer",
          },
        },
      },
    },
    config = function(_, opts)
      if vim.fn.has "win32" == 1 then
        require("nvim-treesitter.install").compilers = { "clang" }
      end
      if treesitter_dev then
        require("nvim-treesitter").setup(opts)
      else
        require("nvim-treesitter.configs").setup(opts)
      end
    end,
    dependencies = {
      {
        "folke/twilight.nvim",
        enabled = not treesitter_dev,
        opts = {},
      },
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        enabled = not treesitter_dev,
      },
      {
        "nvim-treesitter/playground",
        enabled = not treesitter_dev,
      },
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        enabled = not treesitter_dev,
      },
      {
        "LiadOZ/nvim-dap-repl-highlights",
        opts = {},
      },
      {
        "nvim-treesitter/nvim-treesitter-context",
        opts = {},
      },
    },
  },
}
