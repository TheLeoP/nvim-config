vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightOnYank", {}),
  desc = "highlights yanked warea",
  callback = function()
    vim.highlight.on_yank()
  end,
})
