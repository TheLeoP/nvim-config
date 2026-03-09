return {
  "mason-org/mason.nvim",
  build = ":MasonUpdate",
  ---@type MasonSettings
  opts = {
    registries = {
      "github:mason-org/mason-registry",
      "github:Crashdummyy/mason-registry",
    },
  },
  config = function(_, opts)
    require("mason").setup(opts)
    local mr = require "mason-registry"

    mr.refresh(function()
      for _, tool in ipairs {
        "black",
        "stylua",
        "prettierd",
        "hadolint",
        "cpptools",
        "csharpier",
        "debugpy",
        "netcoredbg",
        "sql-formatter",
        "java-debug-adapter",
        "java-test",
        "delve",
        "powershell-editor-services",
        "js-debug-adapter",
        "pretty-php",
        "npm-groovy-lint",

        -- since this comes from a custom registry, it is not auto-installed by mason-lspconfig
        "roslyn",
      } do
        local p = mr.get_package(tool)
        if not p:is_installed() then p:install() end
      end
    end)
  end,
}
