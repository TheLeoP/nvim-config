vim.pack.add { "https://github.com/dont-be-evil-company/kulala.nvim" }
local kulala = require "kulala"
kulala.setup {
  kulala_keymaps_prefix = "'",
  treesitter = {
    enable = false,
  },
}
vim.keymap.set("n", "[k", function()
  kulala.jump_prev()
end)
vim.keymap.set("n", "]k", function()
  kulala.jump_next()
end)
vim.keymap.set("n", "<leader>kr", function()
  kulala.run()
end)
vim.keymap.set("n", "<leader>kt", function()
  kulala.toggle_view()
end)

local group = vim.api.nvim_create_augroup("personal.kulala", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "TSUpdate",
  callback = function()
    require("nvim-treesitter.parsers").kulala_http = {
      install_info = {
        url = "https://github.com/dont-be-evil-company/tree-sitter-kulala-http",
        queries = "queries/kulala_http",
      },
    }
  end,
})
vim.treesitter.language.register("kulala_http", { "http", "rest" })
vim.treesitter.language.register("markdwon", { "kulala_ui" })
