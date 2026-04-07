local data_path = vim.fn.stdpath "data"
vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"

vim.g.db_ui_auto_execute_table_helpers = 1

vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_use_nerd_fonts = 1

vim.g.db_ui_use_nvim_notify = 1

vim.g.db_ui_execute_on_save = false

vim.pack.add {
  "https://github.com/tpope/vim-dadbod",
  "https://github.com/kristijanhusak/vim-dadbod-ui",
  "https://github.com/kristijanhusak/vim-dadbod-completion",
}
