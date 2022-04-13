require'nvim-treesitter.configs'.setup {
  ensure_installed = 'all',
  ignore_install = {
    'markdown',
    'help'
  },
  highlight = {
    enable = true,              -- false will disable the whole extension
    disable = {
      'vim',
      'dashboard'
    }
  },
  incremental_selection = {
    enable = false,
    keymap = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
  indent = {
    enable = false
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
      }
    }
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
}
