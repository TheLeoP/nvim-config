return {
  "mbbill/undotree",
  init = function()
    if vim.fn.has "win32" == 1 then vim.env.PATH = vim.env.PATH .. ";C:\\Program Files\\Git\\usr\\bin\\" end
  end,
}
