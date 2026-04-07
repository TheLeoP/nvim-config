vim.pack.add { "https://github.com/rcarriga/nvim-notify" }

---@diagnostic disable-next-line: missing-fields
require("notify").setup {
  timeout = 300,
  background_colour = "#282828",
}

vim.keymap.set("n", "<c-l>", function()
  vim.cmd.nohlsearch()
  if vim.fn.getcmdwintype() == "" then
    vim.cmd.diffupdate()
    require("notify").dismiss { silent = true, pending = true }
  end

  require("personal.util.general").clear_system_notifications()

  vim.cmd.normal { vim.keycode "<c-l>", bang = true }
end)
vim.notify = require "notify"
