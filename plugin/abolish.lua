vim.api.nvim_create_user_command("S", require("personal.abolish").subvert_dispatcher, {
  bang = true,
  bar = true,
  nargs = 1,
  complete = require("personal.abolish").complete,
  force = true,
  range = 0,
  preview = require("personal.abolish").subvert_preview,
})

vim.api.nvim_create_user_command("F", require("personal.abolish").find_dispatcher, {
  bang = true,
  bar = true,
  nargs = 1,
  complete = require("personal.abolish").complete,
  force = true,
  range = 0,
})

vim.keymap.set("n", "cr", function()
  return require("personal.abolish").coerce() .. "iw"
end, { expr = true, desc = "Coerce iw" })

vim.keymap.set("n", "cR", require("personal.abolish").coerce, { expr = true, desc = "Coerce operator" })
