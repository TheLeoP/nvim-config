return {
  "mason-org/mason.nvim",
  build = ":MasonUpdate",
  opts = {},
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
      } do
        local p = mr.get_package(tool)
        if not p:is_installed() then p:install() end
      end
    end)
  end,
}
