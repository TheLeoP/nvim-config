require("personal.util.writing").setup()

-- automatically continue lists
vim.opt_local.comments = {
  "b:-",
  "b:~",
}
vim.opt_local.formatoptions:append "r"
vim.opt_local.formatoptions:remove "c"
