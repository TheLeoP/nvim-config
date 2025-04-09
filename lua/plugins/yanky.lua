local keymap = vim.keymap
local api = vim.api
return {
  "gbprod/yanky.nvim",
  opts = {
    highlight = {
      timer = 150,
    },
    textobj = {
      enabled = true,
    },
  },
  init = function()
    api.nvim_set_hl(0, "YankyPut", { link = "Visual" })
    api.nvim_set_hl(0, "YankyYanked", { link = "Visual" })
  end,
  config = function(_, opts)
    require("yanky").setup(opts)

    keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
    keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
    keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
    keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")

    keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
    keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)")
    keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)")

    keymap.set({ "o", "x" }, "iy", function() require("yanky.textobj").last_put() end, { desc = "In put (yank)" })
    keymap.set({ "o", "x" }, "ay", function() require("yanky.textobj").last_put() end, { desc = "At put (yank)" })
  end,
}
