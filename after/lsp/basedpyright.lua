return {
  ---@param buf integer
  ---@param cb fun(root_dir: string)
  root_dir = function(buf, cb)
    local root = vim.fs.root(buf, {
      "setup.cfg",
      "pyproject.toml",
      "setup.cfg",
      "requirements.txt",
      "Pipfile",
      "pyrightconfig.json",
    })
    if not root then return end
    cb(root)
  end,
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
      },
    },
  },
}
