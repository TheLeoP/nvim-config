local bujo = require "personal.bujo"
vim.keymap.set("n", "<leader>b", function()
  bujo.open(40)
end, { desc = "Open todo.md" })
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "todo.md",
  callback = function()
    local repo = vim.fn.expand "%:p:h:t"
    vim.api.nvim_buf_set_lines(0, 0, 0, true, { ("# %s todo"):format(repo) })
  end,
})
