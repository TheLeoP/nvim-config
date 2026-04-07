vim.pack.add { "https://github.com/TheLeoP/project.nvim" }

require("project_nvim").setup {
  detection_methods = { "lsp", "pattern" },
  ignore_lsp = { "lemminx", "dockerls", "kulala" },
  scope_chdir = "tab",
  patterns = {
    "!>packages",
    "index.norg",
    ".git",
  },
}
