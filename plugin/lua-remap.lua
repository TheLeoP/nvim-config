-- Toggle the quickfix/loclist window.
-- When toggling these, ignore error messages and restore the cursor to the original window when opening the list.
local silent_mods = { mods = { silent = true, emsg_silent = true } }
vim.keymap.set("n", "<leader>lq", function()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd.cclose(silent_mods)
  elseif #vim.fn.getqflist() > 0 then
    local win = vim.api.nvim_get_current_win()
    vim.cmd.copen(silent_mods)
    if win ~= vim.api.nvim_get_current_win() then vim.cmd.wincmd "p" end
  end
end, { desc = "Toggle quickfix list" })
vim.keymap.set("n", "<leader>ll", function()
  if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
    vim.cmd.lclose(silent_mods)
  elseif #vim.fn.getloclist(0) > 0 then
    local win = vim.api.nvim_get_current_win()
    vim.cmd.lopen(silent_mods)
    if win ~= vim.api.nvim_get_current_win() then vim.cmd.wincmd "p" end
  end
end, { desc = "Toggle location list" })

-- Use dressing for spelling suggestions.
vim.keymap.set("n", "z=", function()
  vim.ui.select(
    vim.fn.spellsuggest(vim.fn.expand "<cword>"),
    {},
    vim.schedule_wrap(function(selected)
      if selected then vim.cmd("normal! ciw" .. selected) end
    end)
  )
end, { desc = "Spelling suggestions" })

vim.keymap.set("c", "Mes", "mes")
