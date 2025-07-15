return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.lsp.enable {
      "basedpyright",
      "angularls",
      "fennel_language_server",
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
    }

    -- NOTE: disable bultin query linter, `ts_query_ls` is more complete
    vim.g.query_lint_on = {}
  end,
}
