return {
  "mbbill/undotree",
  init = function()
    if vim.fn.has "win32" == 1 then vim.g.undotree_DiffCommand = "FC" end
  end,
}
