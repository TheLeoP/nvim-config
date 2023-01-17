require("project_nvim").setup {
  detection_methods = { "pattern", "lsp" },
  ignore_lsp = { "null-ls", "emmet_ls" },
  show_hidden = true,
  scope_chdir = "tab",
  patterns = {
    "!>Documentos",
    "!>Lucho",
    "build.gradle",
    "package.json",
    ".git",
    "_darcs",
    ".hg",
    ".bzr",
    ".svn",
    "Makefile",
    "go.mod",
  },
}
