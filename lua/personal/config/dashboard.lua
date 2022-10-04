local db = require "dashboard"

db.custom_header = {
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
}

db.custom_center = {
  {
    icon = " ",
    desc = "Archivos recientes",
    action = "Telescope oldfiles",
  },
  {
    icon = " ",
    desc = "Proyectos recientes",
    action = "Telescope project",
  },
  {
    icon = " ",
    desc = "Cargar sesión",
    action = "Telescope possession list",
  },
}

db.custom_footer = {
  "A veces un hipócrita no es más que una persona en proceso de cambio. -Dalinar Kholin",
}

db.hide_statusline = false
db.hide_tabline = false
db.hide_winbar = false

db.header_pad = 0
db.center_pad = 5
db.footer_pad = 10

vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#71A9B4" })
vim.api.nvim_set_hl(0, "DashboardCenter", { fg = "#7ebe88" })
vim.api.nvim_set_hl(0, "DashboardFooter", { fg = "#CAB8A3" })
