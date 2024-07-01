return {
  "pmizio/typescript-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local config = require "personal.config.lsp"

    require("typescript-tools").setup {
      capabilities = config.capabilities,
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayEnumMemberValueHints = true,
        },
        expose_as_code_action = {
          "add_missing_imports",
          "remove_unused_imports",
          "organize_imports",
        },
      },
    }
  end,
}
