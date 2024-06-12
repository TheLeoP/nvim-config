require("personal.util.writing").setup()

-- automatically continue lists
vim.opt_local.comments = {
  "b:-",
  "b:--",
  "b:---",
  "b:----",
  "b:~",
  "b:~~",
  "b:~~~",
  "b:~~~~",
}
