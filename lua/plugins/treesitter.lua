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
        opts = {},
        config = function(_, opts)
          require("nvim-treesitter-textobjects").setup(opts)

          vim.keymap.set(
            { "n", "x" },
            "<leader>df",
            function()
              require("nvim-treesitter-textobjects.lsp_interop").peek_definition_code("@function.outer", "textobjects")
            end
          )

          vim.keymap.set(
            { "n", "x", "o" },
            "[f",
            function() require("nvim-treesitter-textobjects.move").goto_previous "@function.outer" end
          )
          vim.keymap.set(
            { "n", "x", "o" },
            "]f",
            function() require("nvim-treesitter-textobjects.move").goto_next "@function.outer" end
          )

          vim.keymap.set(
            "o",
            "<F5>",
            function()
              require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects", "o")
            end
          )
          vim.keymap.set(
            "o",
            "<S-F5>",
            function()
              require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects", "o")
            end
          )
          vim.keymap.set(
            "x",
            "<F5>",
            function()
              require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects", "x")
            end
          )
          vim.keymap.set(
            "x",
            "<S-F5>",
            function()
              require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects", "x")
            end
          )

          vim.keymap.set("n", "<F6>", require("nvim-treesitter-textobjects.swap").swap_next "@parameter.inner")
          vim.keymap.set("n", "<S-F6>", require("nvim-treesitter-textobjects.swap").swap_previous "@parameter.inner")
        end,
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
