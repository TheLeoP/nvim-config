return {
  "pmizio/typescript-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "blink.cmp" },
  config = function()
    require("typescript-tools").setup {
      capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
      root_dir = function()
        return vim.fs.root(0, {
          ".git",
        }) or vim.fs.root(0, { "package.json" })
      end,
      settings = {
        tsserver_max_memory = "10240",
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
