local keymap = vim.keymap

return {
  "theprimeagen/refactoring.nvim",
  dev = true,
  config = function()
    local refactoring = require "refactoring"

    keymap.set({ "n", "x" }, "<leader>ae", function()
      return refactoring.refactor "Extract Function"
    end, { desc = "Extract Function", expr = true })
    keymap.set({ "n", "x" }, "<leader>af", function()
      return refactoring.refactor "Extract Function To File"
    end, { desc = "Extract Function To File", expr = true })
    keymap.set({ "n", "x" }, "<leader>av", function()
      return refactoring.refactor "Extract Variable"
    end, { desc = "Extract Variable", expr = true })
    keymap.set({ "n", "x" }, "<leader>ai", function()
      return refactoring.refactor "Inline Variable"
    end, { desc = "Inline Variable", expr = true })
    keymap.set({ "n", "x" }, "<leader>aI", function()
      return refactoring.refactor(115)
    end, { desc = "Inline function", expr = true })

    keymap.set("n", "<leader>pP", function()
      refactoring.debug.printf { below = false }
    end, { desc = "Debug print above" })
    keymap.set("n", "<leader>pp", function()
      refactoring.debug.printf { below = true }
    end, { desc = "Debug print below" })
    keymap.set({ "x", "n" }, "<leader>pV", function()
      refactoring.debug.print_var { below = false }
    end, { desc = "Debug print var above" })
    keymap.set({ "x", "n" }, "<leader>pv", function()
      refactoring.debug.print_var { below = true }
    end, { desc = "Debug print var below" })
    keymap.set("n", "<leader>pc", function()
      refactoring.debug.cleanup {}
    end, { desc = "Debug print clean" })
  end,
}
