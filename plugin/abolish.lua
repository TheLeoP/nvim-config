vim.api.nvim_create_user_command("S", require("personal.abolish").subvert_dispatcher, {
  bang = true,
  bar = true,
  nargs = "+",
  complete = require("personal.abolish").complete,
  force = true,
  range = 0,
  preview = require("personal.abolish").subvert_preview,
})

vim.api.nvim_create_user_command("Subvert", require("personal.abolish").subvert_dispatcher, {
  bang = true,
  bar = true,
  nargs = "+",
  complete = require("personal.abolish").complete,
  force = true,
  range = 0,
  preview = require("personal.abolish").subvert_preview,
})

vim.keymap.set("n", "cr", function()
  return require("personal.abolish").opertator_func() .. "iw"
end, { expr = true })
