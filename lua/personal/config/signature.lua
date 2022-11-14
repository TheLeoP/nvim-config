require("lsp_signature").setup {
  bind = true,
  doc_lines = 0,
  floating_windows = true,
  floating_window_above_cur_line = true,
  floating_window_off_x = 66,
  fix_pos = true,
  hint_enable = false,
  handler_opts = {
    border = vim.g.lsp_borders,
  },
}
