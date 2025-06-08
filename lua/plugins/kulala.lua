return {
  "mistweaverco/kulala.nvim",
  opts = {},
  config = function(_, opts)
    local kulala = require "kulala"
    kulala.setup(opts)
    vim.keymap.set("n", "[k", function()
      kulala.jump_prev()
    end)
    vim.keymap.set("n", "]k", function()
      kulala.jump_next()
    end)
    vim.keymap.set("n", "<leader>kr", function()
      kulala.run()
    end)
    vim.keymap.set("n", "<leader>kt", function()
      kulala.toggle_view()
    end)
  end,
}
