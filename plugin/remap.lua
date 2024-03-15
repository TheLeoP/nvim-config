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
      if selected then vim.cmd([[normal! "_ciw]] .. selected) end
    end)
  )
end, { desc = "Spelling suggestions" })

vim.keymap.set("c", "Mes", "mes")

-- execute current buffer
vim.keymap.set({ "n" }, "<leader><leader>x", function()
  if vim.bo.filetype == "lua" then
    vim.cmd "silent! write"
    vim.cmd "source %"
  elseif vim.bo.filetype == "vim" then
    vim.cmd "silent! write"
    vim.cmd "source %"
  elseif vim.bo.filetype == "fennel" then
    vim.cmd "FnlBuffer"
  else
    vim.notify(("The current filetype is `%s`"):format(vim.bo.filetype), vim.log.levels.WARN)
  end
end, { desc = "Execute current buffer (vim or lua)" })

vim.keymap.set({ "n" }, "<leader><leader>t", "<cmd>tab split<cr>")

-- jumplist on j and k

vim.keymap.set("n", "j", [[(v:count ? "m'" . v:count : "") . "gj"]], { buffer = true, expr = true })
vim.keymap.set("n", "k", [[(v:count ? "m'" . v:count : "") . "gk"]], { buffer = true, expr = true })

-- telescope

vim.keymap.set({ "n" }, "<leader>fi", function()
  local builtin = require "telescope.builtin"
  return builtin.find_files { prompt_title = "< Nvim config >", cwd = vim.fn.stdpath "config" }
end, { desc = "Fuzzy search files in nvim config", silent = true })

vim.keymap.set({ "n" }, "<leader>fI", function()
  local telescope = require "telescope"
  return telescope.extensions.live_grep_args.live_grep_args {
    prompt_title = "< Rg nvim_config >",
    cwd = vim.fn.stdpath "config",
  }
end, { desc = "Rg in nvim config", silent = true })
