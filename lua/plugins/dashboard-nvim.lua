return {
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
          action = "FzfLua oldfiles",
        },
        {
          icon = " ",
          desc = "Proyectos recientes",
          action = require("personal.fzf-lua").projects,
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
}
