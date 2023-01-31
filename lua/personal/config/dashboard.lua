local db = require "dashboard"
db.setup {
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
        icon = " ",
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
}

vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#71A9B4" })
vim.api.nvim_set_hl(0, "DashboardDesc", { fg = "#7ebe88" })
vim.api.nvim_set_hl(0, "DashboardKey", { fg = "#7ebe88" })
vim.api.nvim_set_hl(0, "DashboardIcon", { fg = "#7ebe88" })
vim.api.nvim_set_hl(0, "DashboardShortCut", { fg = "#7ebe88" })
vim.api.nvim_set_hl(0, "DashboardFooter", { fg = "#CAB8A3" })
