return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.lsp.enable "basedpyright"
    vim.lsp.enable "angularls"
    vim.lsp.enable "fennel_language_server"
    vim.lsp.enable "vimls"
    vim.lsp.enable "buf_ls"
    vim.lsp.enable "html"
    vim.lsp.enable "cssls"
    vim.lsp.enable "lemminx"
    vim.lsp.enable "phpactor"
    vim.lsp.enable "prismals"
    vim.lsp.enable "marksman"
    vim.lsp.enable "dockerls"
    vim.lsp.enable "docker_compose_language_service"
    vim.lsp.enable "lua_ls"
    vim.lsp.enable "gopls"
    vim.lsp.enable "jsonls"
    vim.lsp.enable "groovyls"
    vim.lsp.enable "emmet_language_server"
    vim.lsp.enable "tailwindcss"
    vim.lsp.enable "clangd"
  end,
}
