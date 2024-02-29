local M = {}

function M.setup()
  vim.wo.spell = true
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.wo.conceallevel = 3

  vim.b.undo_ftplugin = "setlocal nospell nowrap nolinebreak conceallevel=0"

  vim.keymap.set("n", "j", "v:count ? 'j' : 'gj'", { buffer = true, expr = true })
  vim.keymap.set("n", "k", "v:count ? 'k' : 'gk'", { buffer = true, expr = true })
  vim.keymap.set("n", "gj", "j", { buffer = true })
  vim.keymap.set("n", "gk", "k", { buffer = true })
end

return M
