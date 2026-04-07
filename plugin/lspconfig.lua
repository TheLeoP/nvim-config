vim.pack.add {
  "https://github.com/b0o/schemastore.nvim",
  "https://github.com/neovim/nvim-lspconfig",
}

vim.lsp.enable {
  "basedpyright",
  "angularls",
  "vimls",
  "buf_ls",
  "html",
  "cssls",
  "lemminx",
  "phpactor",
  "prismals",
  "marksman",
  "dockerls",
  "docker_compose_language_service",
  "lua_ls",
  "gopls",
  "jsonls",
  "groovyls",
  "tailwindcss",
  "clangd",
  "ts_query_ls",
  "laravel_ls",
}

-- disables bultin query linter, `ts_query_ls` is more complete
vim.g.query_lint_on = {}
