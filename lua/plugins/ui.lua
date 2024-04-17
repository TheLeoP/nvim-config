return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("gruvbox").setup {
        overrides = {
          DiagnosticHint = { link = "GruvboxFg2" },
          DiagnosticSignHint = { link = "GruvboxFg2" },
          DiagnosticFloatingHint = { link = "GruvboxFg2" },
          DiagnosticUnderlineHint = { undercurl = true, sp = "#d5c4a1" },
          DiagnosticVirtualTextHint = { link = "GruvboxFg2" },

          LspReferenceText = { underline = true, sp = "#d5c4a1" },
          LspReferenceRead = { underline = true, sp = "#d5c4a1" },
          LspReferenceWrite = { underline = true, sp = "#fe8019" },

          FloatBorder = { link = "NormalFloat" },

          FoldColumn = { link = "Normal" },
          Folded = { bg = "#1d2021" },
          SignColumn = { link = "Normal" },

          debugPC = { bg = "#1d2021" },

          TreesitterContextBottom = { underline = true, sp = "#665c54" },
        },
        italic = {
          strings = false,
          comments = true,
          operators = false,
          folds = false,
          emphasis = false,
        },
        inverse = true,
      }
      vim.cmd.colorscheme "gruvbox"
    end,
  },
  {
    "stevearc/dressing.nvim",
    opts = {
      input = {
        insert_only = false,
        start_in_insert = false,
        border = "single",
        win_options = {
          winblend = 0,
        },
      },
      select = {
        backend = { "fzf_lua", "nui", "builtin" },
      },
    },
  },
  {
    "rcarriga/nvim-notify",
    keys = {
      {
        mode = "n",
        "<c-l>",
        function()
          pcall(vim.cmd.nohlsearch)
          pcall(vim.cmd.diffupdate)
          pcall(require("notify").dismiss, { silent = true, pending = true })
          pcall(vim.cmd.normal, { "\12", bang = true }) -- ctrl-l
        end,
      },
    },
    init = function()
      vim.o.termguicolors = true
      vim.notify = require "notify"
    end,
    config = function() require("notify").setup() end,
  },
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      filetypes = {
        "css",
        "javascript",
        "typescript",
        "typescriptreact",
        "javascriptreact",
        "vue",
        "html",
        "dbout",
        "sql",
        "lua",
      },
      user_default_options = {
        tailwind = true,
      },
    },
  },
  {
    "nvim-tree/nvim-web-devicons",
    opts = {
      default = true,
    },
  },
}
