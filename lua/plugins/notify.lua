return {
  "rcarriga/nvim-notify",
  ---@module "notify"
  ---@type notify.Config
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    timeout = 300,
    background_colour = "#282828",
  },
  config = function(_, opts)
    vim.o.termguicolors = true
    require("notify").setup(opts)
    vim.keymap.set("n", "<c-l>", function()
      vim.cmd.nohlsearch()
      if vim.fn.getcmdwintype() == "" then
        vim.cmd.diffupdate()
        require("notify").dismiss { silent = true, pending = true }
      end

      require("personal.util.general").clear_system_notifications()

      vim.cmd.normal { "\12", bang = true } --[[ ctrl-l]]
    end)

    vim.notify = require "notify"
  end,
}
