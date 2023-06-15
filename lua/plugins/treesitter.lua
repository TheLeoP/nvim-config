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
            ["ao"] = "@block.outer",
            ["io"] = "@block.inner",
          },
          selection_modes = {
            ["@function.outer"] = "v",
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
      if treesitter_dev then
        require("nvim-treesitter").setup(opts)
      else
        require("nvim-treesitter.configs").setup(opts)
      end
    end,
    dependencies = {
      {
        "folke/twilight.nvim",
        config = true,
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
        "windwp/nvim-ts-autotag",
        enabled = not treesitter_dev,
      },
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        enabled = not treesitter_dev,
      },
      {
        "andymass/vim-matchup",
        enabled = not treesitter_dev,
      },
    },
  },
}
