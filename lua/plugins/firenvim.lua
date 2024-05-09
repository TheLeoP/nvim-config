return {
  "glacambre/firenvim",
  cond = vim.g.started_by_firenvim ~= nil,
  init = function()
    vim.g.firenvim_config = {
      globalSettings = {
        alt = "all",
        ["<C-w>"] = "noop",
        ["<C-n>"] = "default",
        ["<C-t>"] = "default",
        takeover = "never",
      },
      localSettings = {
        [".*"] = {
          takeover = "never",
          priority = 999,
        },
      },
    }
  end,
  config = function()
    vim.o.laststatus = 0
    vim.o.winbar = nil
  end,
  build = function() vim.fn["firenvim#install"](0) end,
}
