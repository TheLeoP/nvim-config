local lazydev = require "lazydev"
---@type vim.lsp.Config
return {
  settings = {
    Lua = {
      hint = {
        enable = true,
        arrayIndex = "Disable",
      },
      codelens = {
        enable = true,
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
        libraryFiles = "Disabled",
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
