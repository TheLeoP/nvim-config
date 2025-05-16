return {
  "mason-org/mason-lspconfig.nvim",
  dependencies = { "mason.nvim", "nvim-lspconfig" },
  ---@module 'mason-lspconfig'
  ---@type MasonLspconfigSettings
  opts = {
    ensure_installed = {
      "jdtls",

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
    },
    automatic_enable = false,
  },
}
