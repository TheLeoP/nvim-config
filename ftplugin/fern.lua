local ctrlL = function()
  require("notify").dismiss { silent = true }
  vim.fn["fern#action#call"] "redraw"
  vim.cmd.nohlsearch()
  vim.cmd.diffupdate()
  vim.cmd.normal { "", bang = true }
end
vim.keymap.set("n", "<c-space>", "<Plug>(fern-action-mark)", { buffer = true })
vim.keymap.set("n", "-", "<Plug>(fern-action-leave)", { buffer = true })
vim.keymap.set("n", "<c-l>", ctrlL, { buffer = true })
vim.keymap.set("n", "g?", "<Plug>(fern-action-help)", { buffer = true, remap = true })

vim.fn["glyph_palette#apply"]()
