vim.api.nvim_create_user_command("S", require("personal.abolish").subvert_dispatcher, {
  bang = true,
  bar = true,
  nargs = 1,
  complete = require("personal.abolish").complete,
  force = true,
  range = 0,
  preview = require("personal.abolish").subvert_preview,
})

vim.api.nvim_create_user_command("Subvert", require("personal.abolish").subvert_dispatcher, {
  bang = true,
  bar = true,
  nargs = 1,
  complete = require("personal.abolish").complete,
  force = true,
  range = 0,
  preview = require("personal.abolish").subvert_preview,
})

vim.keymap.set("n", "cr", function()
  local aux = require("personal.abolish").opertator_func()
  if not aux then return end
  return aux .. "iw"
end, { expr = true })

vim.keymap.set({ "v", "n" }, "<leader>cr", require("personal.abolish").opertator_func, { expr = true })
