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
  local motion = require("personal.abolish").operator_func()
  if not motion then return end
  return motion .. "iw"
end, { expr = true })

vim.keymap.set({ "v", "n" }, "<leader>cr", require("personal.abolish").operator_func, { expr = true })
