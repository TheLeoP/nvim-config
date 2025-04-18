local arrows = require("personal.icons").arrows
local keymap = vim.keymap

return {
  "rcarriga/nvim-dap-ui",
  opts = {
    floating = {
      border = "none",
    },
    icons = {
      collapsed = arrows.right,
      current_frame = arrows.right,
      expanded = arrows.down,
    },
    layouts = {
      {
        elements = {
          {
            id = "scopes",
            size = 0.50,
          },
          {
            id = "watches",
            size = 0.20,
          },
          {
            id = "stacks",
            size = 0.30,
          },
        },
        position = "right",
        size = 50,
      },
    },
  },
  config = function(_, opts)
    local dapui = require "dapui"
    dapui.setup(opts)

    keymap.set("n", "<leader>ta", dapui.toggle, { desc = "Toggle D[A]P Ui" })
  end,
  dependencies = {
    "nvim-dap",
    "nvim-neotest/nvim-nio",
  },
}
