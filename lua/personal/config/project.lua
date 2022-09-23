require("project_nvim").setup {
  ignore_lsp = { "null-ls", "emmet_ls", "volar_api", "volar_doc" },
  show_hidden = true,
  patterns = {
    "build.gradle",
    "package.json",
    ".git",
    "_darcs",
    ".hg",
    ".bzr",
    ".svn",
    "Makefile",
  },
}
