vim.pack.add { "https://github.com/mason-org/mason.nvim" }

require("mason").setup {
  registries = {
    "github:mason-org/mason-registry",
    "github:Crashdummyy/mason-registry",
  },
}
local mr = require "mason-registry"

mr.refresh(function()
  for _, tool in ipairs {
    "black",
    "stylua",
    "prettierd",
    "hadolint",
    "cpptools",
    "csharpier",
    "sql-formatter",
    "pretty-php",
    "npm-groovy-lint",

    "debugpy",
    "netcoredbg",
    "java-debug-adapter",
    "java-test",
    "delve",
    "js-debug-adapter",

    "roslyn",
    "jdtls",
    "powershell-editor-services",
    "basedpyright",
    "angular-language-server",
    "vim-language-server",
    "buf-language-server",
    "html-lsp",
    "css-lsp",
    "lemminx",
    "phpactor",
    "prisma-language-server",
    "marksman",
    "docker-language-server",
    "docker-compose-language-service",
    "lua-language-server",
    "gopls",
    "json-lsp",
    "groovy-language-server",
    "tailwindcss-language-server",
    "clangd",
    "ts_query_ls",
  } do
    local p = mr.get_package(tool)
    if not p:is_installed() then p:install() end
  end
end)
