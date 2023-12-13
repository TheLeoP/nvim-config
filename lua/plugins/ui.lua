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
    "nvimdev/dashboard-nvim",
    lazy = false,
    opts = {
      theme = "doom",
      config = {
        header = {
          "",
          "",
          " ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
          " ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
          " ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
          " ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
          " ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
          " ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
        },
        center = {
          {
            icon = " ",
            desc = "Archivos recientes",
            action = "Telescope oldfiles",
          },
          {
            icon = " ",
            desc = "Proyectos recientes",
            action = "Telescope projects",
          },
          {
            icon = " ",
            desc = "Cargar sesión",
            action = "SessionManager load_session",
          },
        },
        footer = {
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "A veces un hipócrita no es más que una persona en proceso de cambio. -Dalinar Kholin",
        },
      },
      hide = {
        statusline = false,
        tabline = false,
        winbar = false,
      },
    },
    config = function(_, opts)
      vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#71A9B4" })
      vim.api.nvim_set_hl(0, "DashboardDesc", { fg = "#7ebe88" })
      vim.api.nvim_set_hl(0, "DashboardKey", { fg = "#7ebe88" })
      vim.api.nvim_set_hl(0, "DashboardIcon", { fg = "#7ebe88" })
      vim.api.nvim_set_hl(0, "DashboardShortCut", { fg = "#7ebe88" })
      vim.api.nvim_set_hl(0, "DashboardFooter", { fg = "#CAB8A3" })
      require("dashboard").setup(opts)
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
        backend = { "telescope", "builtin" },
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
          vim.cmd.nohlsearch()
          vim.cmd.diffupdate()
          require("notify").dismiss { silent = true, pending = true }
          vim.cmd.normal { "\12", bang = true } -- ctrl-l
        end,
      },
    },
    init = function()
      vim.o.termguicolors = true
      vim.notify = require "notify"
    end,
    config = function()
      require("notify").setup()
      require("telescope").load_extension "notify"
    end,
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
