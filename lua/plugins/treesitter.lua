return {
  {
    "nvim-treesitter/nvim-treesitter",
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

      local parsers = require "nvim-treesitter.parsers"
      local parser_config = parsers.get_parser_configs()
      parser_config.angular = {
        install_info = {
          url = "https://github.com/ShooTeX/tree-sitter-angular",
          files = { "src/parser.c" },
          branch = "main",
          generate_requires_npm = false,
          requires_generate_from_grammar = false,
        },
      }

      if not parsers.has_parser "angular" then vim.cmd.TSInstallFromGrammar "angular" end
    end,
    dependencies = {
      {
        "folke/twilight.nvim",
        opts = {},
      },
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dev = true,
        opts = {
          move = { enable = true },
          select = { enable = true },
          swap = { enable = true },
          repeatable_move = { enable = true },
          lsp_interop = { enable = true },
        },
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
          multiline_threshold = 2,
        },
      },
      {
        "windwp/nvim-ts-autotag",
      },
    },
  },
}
