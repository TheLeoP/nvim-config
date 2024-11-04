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
    require("notify").setup(opts)
    vim.keymap.set("n", "<c-l>", function()
      vim.cmd.nohlsearch()
      vim.cmd.diffupdate()
      require("notify").dismiss { silent = true, pending = true }
      vim.cmd.normal { "\12", bang = true } --[[ ctrl-l]]
    end)

    vim.notify = require "notify"
  end,
}
