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
      incremental_selection = {
        enable = true,
        keymap = {
          init_selection = "gnn",
          node_incremental = "grn",
          node_decremental = "grm",
          scope_incremental = "grc",
        },
      },
      indent = {
        enable = false,
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
            -- ["ab"] = "@block.outer",
            -- ["ib"] = "@block.inner",
          },
          selection_modes = {
            ["@function.outer"] = "V",
            ["@class.outer"] = "V",
            ["@block.outer"] = "V",
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader><leader>k"] = "@parameter.inner",
          },
          swap_previous = {
            ["<leader><leader>j"] = "@parameter.inner",
          },
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
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
      autotag = {
        enable = true,
      },
      context_commentstring = {
        enable = true,
      },
      playground = {
        enable = true,
      },
      matchup = {
        enable = true,
      },
    },
    config = function(_, opts)
      if vim.fn.has "win32" == 1 then
        require("nvim-treesitter.install").compilers = { "clang" }
      end
      require("nvim-treesitter.configs").setup(opts)
    end,
    dependencies = {
      {
        "folke/twilight.nvim",
        config = true,
      },
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/playground",
      "windwp/nvim-ts-autotag",
      "JoosepAlviste/nvim-ts-context-commentstring",
      "andymass/vim-matchup",
    },
  },
}