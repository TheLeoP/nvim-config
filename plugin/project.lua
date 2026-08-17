-- NOTE: check if no other plugin depends on async.nvim when removing plugin
vim.pack.add { "https://github.com/TheLeoP/project.nvim" }

require("project_nvim").setup {
  detection_methods = { "lsp", "pattern" },
  ignore_lsp = { "lemminx", "dockerls", "kulala", "yamlls", "helm_ls" },
  scope_chdir = "tab",
  patterns = {
    "!>packages",
    "index.norg",
    ".git",
  },
}
