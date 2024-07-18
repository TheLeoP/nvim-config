return {
  "mbbill/undotree",
  init = function()
    if vim.fn.has "win32" == 1 then vim.g.undotree_DiffCommand = '"C:/Program Files/Git/usr/bin/diff"' end
  end,
}
