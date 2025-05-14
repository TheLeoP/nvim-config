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
      "emmet_language_server",
      "tailwindcss",
      "clangd",
    }
  end,
}
