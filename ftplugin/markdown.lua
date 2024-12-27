require("personal.util.writing").setup()

-- <c-bs>
vim.keymap.set("n", "\08", function()
  local cur_line = vim.api.nvim_get_current_line()
  local replacement ---@type string
  if cur_line:match "^%s*- %[ %]" then
    replacement = cur_line:gsub("%[ %]", "[x]")
  else
    replacement = cur_line:gsub("%[x%]", "[ ]")
  end
  vim.api.nvim_set_current_line(replacement)
end, { buffer = true })
vim.keymap.set({ "n", "i" }, "<c-cr>", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) --[[@as integer, integer]]
  vim.api.nvim_buf_set_lines(0, row, row, true, { "- [ ] " })
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
  vim.cmd.startinsert { bang = true }
end, { buffer = true })
