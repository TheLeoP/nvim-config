return {
  "TheLeoP/project.nvim",
  lazy = false,
  config = function()
    require("project_nvim").setup {
      detection_methods = { "lsp", "pattern" },
      ignore_lsp = { "emmet_ls", "lemminx" },
      show_hidden = true,
      scope_chdir = "tab",
      patterns = {
        "!>packages",
        "index.norg",
        ".git",
      },
    }
  end,
}
