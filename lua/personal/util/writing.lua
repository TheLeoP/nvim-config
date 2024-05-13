local M = {}

function M.setup()
  vim.opt_local.spell = true
  vim.opt_local.wrap = true
  vim.opt_local.linebreak = true
  vim.opt_local.conceallevel = 3

  vim.b.undo_ftplugin = "setlocal nospell nowrap nolinebreak conceallevel=0"

  vim.keymap.set("n", "gj", "j", { buffer = true })
  vim.keymap.set("n", "gk", "k", { buffer = true })
end

return M
