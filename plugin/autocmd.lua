local group = vim.api.nvim_create_augroup("HighlightOnYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "highlights yanked warea",
  callback = function()
    vim.highlight.on_yank()
  end,
})
