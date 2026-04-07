vim.pack.add { "https://github.com/uga-rosa/ccc.nvim" }

require("ccc").setup {
  highlighter = {
    auto_enable = true,
    lsp = false,
    filetypes = {
      "css",
      "javascript",
      "typescript",
      "typescriptreact",
      "javascriptreact",
      "vue",
      "html",
      "dbout",
      "sql",
      "lua",
    },
  },
}
