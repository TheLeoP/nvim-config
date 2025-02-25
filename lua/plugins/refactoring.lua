local keymap = vim.keymap

return {
  "theprimeagen/refactoring.nvim",
  dev = true,
  config = function(_, opts)
    local refactoring = require "refactoring"

    refactoring.setup {
      print_var_statements = {
        javascript = { 'console.log("%s %%s", JSON.stringify(%s));' },
      },
    }

    keymap.set("x", "<leader>ae", function() refactoring.refactor "Extract Function" end, { desc = "Extract Function" })
    keymap.set(
      "x",
      "<leader>af",
      function() refactoring.refactor "Extract Function To File" end,
      { desc = "Extract Function To File" }
    )
    keymap.set("x", "<leader>av", function() refactoring.refactor "Extract Variable" end, { desc = "Extract Variable" })
    keymap.set(
      { "n", "x" },
      "<leader>ai",
      function() refactoring.refactor "Inline Variable" end,
      { desc = "Inline Variable" }
    )
    keymap.set("n", "<leader>aI", function() refactoring.refactor(115) end, { desc = "Inline function" })

    keymap.set(
      "n",
      "<leader>pP",
      function() refactoring.debug.printf { below = false } end,
      { desc = "Debug print above" }
    )
    keymap.set(
      "n",
      "<leader>pp",
      function() refactoring.debug.printf { below = true } end,
      { desc = "Debug print below" }
    )
    keymap.set(
      { "x", "n" },
      "<leader>pV",
      function() refactoring.debug.print_var { below = false } end,
      { desc = "Debug print var above" }
    )
    keymap.set(
      { "x", "n" },
      "<leader>pv",
      function() refactoring.debug.print_var { below = true } end,
      { desc = "Debug print var below" }
    )
    keymap.set("n", "<leader>pc", function() refactoring.debug.cleanup {} end, { desc = "Debug print clean" })
  end,
}
