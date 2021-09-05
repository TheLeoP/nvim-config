vim.g.dashboard_default_executive = 'telescope'
vim.g.dashboard_custom_header = {
 ' ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗',
 ' ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║',
 ' ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║',
 ' ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║',
 ' ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║',
 ' ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝',
}

vim.g.dashboard_custom_section = {
   proyectos_recientes= {
     description= {'  Proyectos recientes    '},
     command= 'Telescope project'
   },
   archivos_recientes= {
     description= {'  Archivos recientes    '},
     command= 'Telescope oldfiles'
   },
   cargar_sesion= {
     description= {'  Cargar sesión    '},
     command= 'lua require("personal.fn_dashboard").cargar_sesion()'
   },
}

vim.g.dashboard_custom_footer = {'42'}
