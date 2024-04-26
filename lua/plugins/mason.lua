local notify_opts = { title = "Ensure installed" }
---@param name string
local function ensure_installed(name)
  local Registry = require "mason-registry"
  local pkg = Registry.get_package(name)
  if not pkg:is_installed() then
    vim.notify(("Installing %s"):format(name), vim.log.levels.INFO, notify_opts)
    pkg:install():once(
      "closed",
      vim.schedule_wrap(function()
        if pkg:is_installed() then
          vim.notify(("%s was installed"):format(pkg.name), vim.log.levels.INFO, notify_opts)
        else
          vim.notify(("failed to install %s"):format(pkg.name), vim.log.levels.ERROR)
        end
      end)
    )
  end
end

---@type string[]
local tools = {
  "eslint_d",
  "black",
  "stylua",
  "prettierd",
}

return {
  "williamboman/mason.nvim",
  build = ":MasonUpdate",
  config = function()
    require("mason").setup {}
    for _, tool in ipairs(tools) do
      ensure_installed(tool)
    end
  end,
}
