require("nvim-treesitter.configs").setup {
  ensure_installed = "all",
  ignore_install = {
    -- 'markdown',
  },
  highlight = {
    enable = true, -- false will disable the whole extension
    disable = {
      -- 'vim',
      "dashboard",
      -- 'html'
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
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
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
}
