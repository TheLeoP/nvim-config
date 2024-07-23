return {
  {
    "ggandor/leap.nvim",
    dependencies = { "tpope/vim-repeat" },
    config = function()
      local leap = require "leap"
      leap.opts.equivalence_classes = { " \t\r\n", "([{", ")]}", "'\"`" }
      leap.opts.special_keys.prev_target = "<up>"
      leap.opts.special_keys.prev_group = "<up>"
      leap.opts.special_keys.next_target = "<down>"
      require("leap.user").set_repeat_keys("<down>", "<up>")

      vim.keymap.set({ "n" }, "s", function() leap.leap {} end)
      vim.keymap.set({ "x", "o" }, "s", function() leap.leap { offset = -1, inclusive_op = true } end)
      vim.keymap.set({ "n" }, "S", function() leap.leap { backward = true } end)
      vim.keymap.set({ "x", "o" }, "S", function()
        vim.cmd.normal "v" -- simulates backward inclusive_op because it's broken on leap.nvim
        leap.leap { backward = true, offset = 2 }
      end)
      vim.keymap.set({ "n", "x", "o" }, "gs", function() require("leap.treesitter").select() end)

      vim.keymap.set({ "x", "o" }, "ir", function()
        local ok, char = pcall(vim.fn.getcharstr)
        if not ok or char == "\27" or not char then return end

        require("leap.remote").action { input = "i" .. char }
      end)

      vim.keymap.set({ "x", "o" }, "ar", function()
        local ok, char = pcall(vim.fn.getcharstr)
        if not ok or char == "\27" or not char then return end

        require("leap.remote").action { input = "a" .. char }
      end)

      vim.keymap.set({ "x", "o" }, "rr", function() require("leap.remote").action { input = "_" } end)

      vim.api.nvim_set_hl(0, "LeapMatch", {
        fg = "#ccff88",
        underline = true,
        nocombine = true,
      })
      vim.api.nvim_set_hl(0, "LeapLabel", {
        fg = "black",
        bg = "#ccff88",
        nocombine = true,
      })
    end,
  },
}
