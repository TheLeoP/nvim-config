vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightOnYank", { clear = true }),
  desc = "Highlights yanked area",
  callback = function()
    -- Setting a priority higher than the LSP references one.
    vim.highlight.on_yank { higroup = "Visual", priority = 250 }
  end,
})

vim.api.nvim_create_autocmd("CmdwinEnter", {
  group = vim.api.nvim_create_augroup("ExecuteCmdAndStay", { clear = true }),
  desc = "Execute command and stay in the command-line window",
  callback = function(args) vim.keymap.set({ "n", "i" }, "<S-CR>", "<cr>q:", { buffer = args.buf }) end,
})

vim.api.nvim_create_autocmd("Filetype", {
  group = vim.api.nvim_create_augroup("Format options", { clear = true }),
  desc = "Remove unwanted flags from format options",
  callback = function() vim.opt.formatoptions:remove "o" end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("Terminal", { clear = true }),
  -- Related https://github.com/neovim/neovim/issues/20726
  desc = "Disable fold inside terminal",
  callback = function()
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.foldenable = false
  end,
})
