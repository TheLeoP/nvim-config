return {
  "theprimeagen/refactoring.nvim",
  dev = true,
  config = function(_, opts)
    local refactoring = require "refactoring"
    vim.keymap.set("x", "<leader>ae", function() refactoring.refactor "Extract Function" end)
    vim.keymap.set("x", "<leader>af", function() refactoring.refactor "Extract Function To File" end)
    vim.keymap.set("x", "<leader>av", function() refactoring.refactor "Extract Variable" end)
    vim.keymap.set({ "n", "x" }, "<leader>ai", function() refactoring.refactor "Inline Variable" end)
    vim.keymap.set("n", "<leader>abb", function() refactoring.refactor "Extract Block" end)
    vim.keymap.set("n", "<leader>abf", function() refactoring.refactor "Extract Block To File" end)
    vim.keymap.set("n", "<leader>pP", function() refactoring.debug.printf { below = false } end)
    vim.keymap.set("n", "<leader>pp", function() refactoring.debug.printf { below = true } end)
    vim.keymap.set({ "x", "n" }, "<leader>pv", function() refactoring.debug.print_var { below = true } end)
    vim.keymap.set({ "x", "n" }, "<leader>pV", function() refactoring.debug.print_var { below = false } end)
    vim.keymap.set("n", "<leader>pc", function() refactoring.debug.cleanup {} end)
    vim.keymap.set("n", "<leader>aI", function() refactoring.refactor(115) end)
  end,
}
