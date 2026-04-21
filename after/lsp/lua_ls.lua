local lazydev = require "lazydev"
---@module "lspconfig"
---@type vim.lsp.Config
return {
  ---@type lspconfig.settings.lua_ls
  settings = {
    Lua = {
      hint = {
        arrayIndex = "Disable",
      },
      completion = {
        showWord = "Disable",
        keywordSnippet = "Disable",
      },
      diagnostics = {
        groupFileStatus = {
          strict = "Opened",
          strong = "Opened",
        },
        groupSeverity = {
          strict = "Warning",
          strong = "Warning",
        },
        unusedLocalExclude = { "_*" },
        libraryFiles = "Disable",
      },
      workspace = {
        checkThirdParty = "Disable",
      },
    },
  },
  root_dir = function(buf, on_dir)
    local root ---@type string|nil

    root = lazydev.find_workspace(buf)
    if root then return on_dir(root) end

    root = vim.fs.root(0, {
      ".luarc.json",
      ".luarc.jsonc",
      ".luacheckrc",
      ".stylua.toml",
      "stylua.toml",
      "selene.toml",
      "selene.yml",
      ".git",
    })
    if root then return on_dir(root) end
  end,
}
