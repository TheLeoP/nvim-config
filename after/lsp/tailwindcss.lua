---@type vim.lsp.Config
return {
  ---@param buf integer
  ---@param cb fun(root_dir: string)
  root_dir = function(buf, cb)
    local root = vim.fs.root(buf, {
      "package.json",
    })
    if not root then return end
    local package_json = root .. "/package.json"
    local file = io.open(package_json)
    if not file then return end
    local content = file:read "*a"
    if not content:find [["tailwindcss":]] then return end

    cb(root)
  end,
}
