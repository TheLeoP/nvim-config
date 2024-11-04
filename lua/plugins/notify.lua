return {
  "rcarriga/nvim-notify",
  ---@module "notify"
  ---@type notify.Config
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    timeout = 300,
  },
  config = function(_, opts)
    vim.o.termguicolors = true
    vim.notify = require "notify"
  end,
  config = function()
    require("notify").setup()
    vim.keymap.set("n", "<c-l>", function()
      pcall(vim.cmd.nohlsearch)
      pcall(vim.cmd.diffupdate)
      pcall(require("notify").dismiss, { silent = true, pending = true })
      pcall(vim.cmd.normal, { "\12", bang = true }) --[[ ctrl-l]]
    end)
  end,
}
