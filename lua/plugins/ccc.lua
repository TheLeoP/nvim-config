---@module "ccc"
return {
  "uga-rosa/ccc.nvim",
  ---@type ccc.Options.P
  opts = {
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
  },
}
