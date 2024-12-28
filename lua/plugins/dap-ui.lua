local arrows = require("personal.icons").arrows

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
  dependencies = {
    "nvim-dap",
    "nvim-nio",
  },
}
