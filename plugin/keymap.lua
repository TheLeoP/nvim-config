local keymap = vim.keymap
local api = vim.api

-- Toggle the quickfix/loclist window.
-- When toggling these, ignore error messages and restore the cursor to the original window when opening the list.
local silent_mods = { mods = { silent = true, emsg_silent = true } }
keymap.set("n", "<leader>tq", function()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd.cclose(silent_mods)
  elseif #vim.fn.getqflist() > 0 then
    local win = api.nvim_get_current_win()
    vim.cmd.copen(silent_mods)
    if win ~= api.nvim_get_current_win() then vim.cmd.wincmd "p" end
  end
end, { desc = "Toggle quickfix list" })
keymap.set("n", "<leader>tl", function()
  if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
    vim.cmd.lclose(silent_mods)
  elseif #vim.fn.getloclist(0) > 0 then
    local win = api.nvim_get_current_win()
    vim.cmd.lopen(silent_mods)
    if win ~= api.nvim_get_current_win() then vim.cmd.wincmd "p" end
  end
end, { desc = "Toggle location list" })

keymap.set("n", "<leader>tp", "<cmd>pclose<cr>")

keymap.set("c", "Mes", "mes")

-- execute current buffer
keymap.set({ "n" }, "<leader><leader>x", function()
  if vim.bo.filetype == "lua" then
    vim.cmd "silent! write"
    vim.cmd "source %"
  elseif vim.bo.filetype == "vim" then
    vim.cmd "silent! write"
    vim.cmd "source %"
  else
    vim.notify(("The current filetype is `%s`"):format(vim.bo.filetype), vim.log.levels.WARN)
  end
end, { desc = "Execute current buffer (vim or lua)" })

keymap.set({ "n" }, "<leader><leader>t", "<cmd>tab split<cr>")

-- jumplist on j and k

keymap.set("n", "j", [[(v:count ? "m'" . v:count : "") . "gj"]], { expr = true })
keymap.set("n", "k", [[(v:count ? "m'" . v:count : "") . "gk"]], { expr = true })

-- toggle options
