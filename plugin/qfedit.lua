local api = vim.api
api.nvim_create_autocmd("BufReadPost", {
  pattern = "quickfix",
  callback = function(opts) require("personal.qfedit").start(opts.buf) end,
  group = api.nvim_create_augroup("qfedit-plugin", {}),
})
