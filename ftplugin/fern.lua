vim.keymap.set("n", "<c-space>", "<Plug>(fern-action-mark)", { buffer = true })
vim.keymap.set("n", "-", "<Plug>(fern-action-leave)", { buffer = true })

vim.fn["glyph_palette#apply"]()
