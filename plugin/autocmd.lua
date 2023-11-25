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
