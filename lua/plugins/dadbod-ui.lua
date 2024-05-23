return {
  "kristijanhusak/vim-dadbod-ui",
  init = function()
    vim.g.db_ui_force_echo_notifications = 1
    vim.g.db_ui_show_database_icon = 1
  end,
  dependencies = { "vim-dadbod" },
}
